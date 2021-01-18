defmodule ChatApiWeb.RegistrationController do
  use ChatApiWeb, :controller

  require Logger

  alias Ecto.Changeset
  alias Plug.Conn
  alias ChatApiWeb.ErrorHelpers

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, params)

  def create(conn, %{"user" => user_params}) when is_map_key(user_params, "invite_token") do
    try do
      invite = ChatApi.UserInvitations.get_user_invitation!(user_params["invite_token"])
      params = Enum.into(user_params, %{"account_id" => invite.account.id})

      cond do
        ChatApi.UserInvitations.expired?(invite) ->
          send_server_error(conn, 403, "Invitation token has expired")

        ChatApi.Accounts.has_reached_user_capacity?(invite.account.id) ->
          send_server_error(
            conn,
            403,
            "Your account has reached the capacity for its current subscription plan. " <>
              "Please contact your admin to upgrade the account."
          )

        true ->
          conn
          |> Pow.Plug.create_user(params)
          |> case do
            {:ok, _user, conn} ->
              # # TODO: figure out what we want to do here -- it's not currently
              # # obvious that a user invitation expires after one use.
              # ChatApi.UserInvitations.expire_user_invitation(invite)
              conn
              |> send_registration_event(invite.account.company_name)
              |> enqueue_welcome_email()
              |> notify_slack()
              |> send_api_token()

            {:error, changeset, conn} ->
              errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
              send_user_create_errors(conn, errors)
          end
      end

      if ChatApi.UserInvitations.expired?(invite) do
        send_server_error(conn, 403, "Invitation token has expired")
      else
        conn
        |> Pow.Plug.create_user(params)
        |> case do
          {:ok, _user, conn} ->
            # # TODO: figure out what we want to do here -- it's not currently
            # # obvious that a user invitation expires after one use.
            # ChatApi.UserInvitations.expire_user_invitation(invite)
            conn
            |> send_registration_event(invite.account.company_name)
            |> enqueue_welcome_email()
            |> notify_slack()
            |> send_api_token()

          {:error, changeset, conn} ->
            errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
            send_user_create_errors(conn, errors)
        end
      end
    rescue
      Ecto.NoResultsError ->
        send_server_error(conn, 403, "Invalid invitation token")
    end
  end

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    if registration_disabled?() do
      send_server_error(conn, 403, "An invitation token is required to register")
    else
      conn
      |> user_with_account_transaction(user_params)
      |> ChatApi.Repo.transaction()
      |> case do
        {:ok, %{conn: conn}} ->
          conn
          |> send_registration_event(user_params["company_name"])
          |> enqueue_welcome_email()
          |> notify_slack()
          |> send_api_token()

        {:error, _op, changeset, _changes} ->
          errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
          send_user_create_errors(conn, errors)
      end
    end
  end

  @spec user_with_account_transaction(Conn.t(), map()) :: Ecto.Multi.t()
  def user_with_account_transaction(conn, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:account, fn _repo, %{} ->
      ChatApi.Accounts.create_account(%{company_name: params["company_name"]})
    end)
    |> Ecto.Multi.run(:conn, fn _repo, %{account: account} ->
      # Users of new accounts should have the admin role by default
      user = Enum.into(params, %{"account_id" => account.id, "role" => "admin"})

      case Pow.Plug.create_user(conn, user) do
        {:ok, _user, conn} ->
          {:ok, conn}

        {:error, reason, _conn} ->
          {:error, reason}
      end
    end)
  end

  @spec enqueue_welcome_email(Conn.t()) :: Conn.t()
  defp enqueue_welcome_email(conn) do
    with %{email: email} <- conn.assigns.current_user do
      %{email: email}
      # Send email 35 mins after registering
      |> ChatApi.Workers.SendWelcomeEmail.new(schedule_in: 35 * 60)
      |> Oban.insert()
    end

    conn
  end

  @spec notify_slack(Conn.t()) :: Conn.t()
  defp notify_slack(conn) do
    with %{email: email} <- conn.assigns.current_user do
      # Putting in an async Task for now, since we don't care if this succeeds
      # or fails (and we also don't want it to block anything)
      Task.start(fn ->
        ChatApi.Slack.Notification.log("A new user has signed up: #{email}")
      end)
    end

    conn
  end

  @spec send_registration_event(Conn.t(), String.t()) :: Conn.t()
  defp send_registration_event(conn, company_name) do
    send_registration_event(conn, company_name, ChatApi.Emails.CustomerIO.enabled?())
  end

  @spec send_registration_event(Conn.t(), String.t(), boolean()) :: Conn.t()
  # If CustomerIO is not enabled, just pass through
  defp send_registration_event(conn, _company_name, false), do: conn

  defp send_registration_event(conn, company_name, true) do
    case conn.assigns.current_user do
      %{email: _email, id: _id} = user ->
        # TODO: should we wrap this in a Task or GenServer process?
        Task.start(fn ->
          ChatApi.Emails.CustomerIO.handle_registration_event(user, company_name)
        end)

        conn

      user ->
        Logger.error("User missing id or email: #{inspect(user)}")

        conn
    end
  end

  defp send_api_token(conn) do
    json(conn, %{
      data: %{
        token: conn.private[:api_auth_token],
        renew_token: conn.private[:api_renew_token]
      }
    })
  end

  defp send_user_create_errors(conn, errors) do
    conn
    |> put_status(500)
    |> json(%{error: %{status: 500, message: "Couldn't create user", errors: errors}})
  end

  defp send_server_error(conn, status_code, message) do
    conn
    |> put_status(status_code)
    |> json(%{error: %{status: status_code, message: message}})
  end

  @spec registration_disabled?() :: boolean()
  defp registration_disabled?() do
    case System.get_env("PAPERCUPS_REGISTRATION_DISABLED") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
