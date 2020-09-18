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

      conn
      |> Pow.Plug.create_user(params)
      |> case do
        {:ok, _user, conn} ->
          if ChatApi.UserInvitations.expired?(invite) do
            send_server_error(conn, 403, "Invitation token has expired")
          else
            # # TODO: figure out what we want to do here -- it's not currently
            # # obvious that a user invitation expires after one use.
            # ChatApi.UserInvitations.expire_user_invitation(invite)
            conn |> send_registration_event() |> enqueue_welcome_email() |> send_api_token()
          end

        {:error, changeset, conn} ->
          errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
          send_user_create_errors(conn, errors)
      end
    rescue
      Ecto.NoResultsError ->
        send_server_error(conn, 403, "Invalid invitation token")
    end
  end

  def create(conn, %{"user" => user_params}) do
    if registration_disabled?() do
      send_server_error(conn, 403, "An invitation token is required to register")
    else
      conn
      |> user_with_account_transaction(user_params)
      |> ChatApi.Repo.transaction()
      |> case do
        {:ok, %{conn: conn}} ->
          conn |> send_registration_event |> enqueue_welcome_email() |> send_api_token()

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
        {:ok, _user, conn} -> {:ok, conn}
        {:error, reason, _conn} -> {:error, reason}
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

  @spec send_registration_event(Conn.t()) :: Conn.t()
  defp send_registration_event(conn) do
    send_registration_event(conn, customer_io_enabled?())
  end

  @spec send_registration_event(Conn.t(), boolean()) :: Conn.t()
  # If CustomerIO is not enabled, just pass through
  defp send_registration_event(conn, false), do: conn

  defp send_registration_event(conn, true) do
    case conn.assigns.current_user do
      %{email: email, id: user_id} ->
        now = :os.system_time(:seconds)

        case Customerio.identify(user_id, %{email: email, created_at: now}) do
          {:ok, _} -> nil
          {:error, result} -> Logger.error(inspect(result))
        end

        case Customerio.track(user_id, "sign_up", %{signed_up_at: now}) do
          {:ok, _} -> nil
          {:error, result} -> Logger.error(inspect(result))
        end

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

  @spec customer_io_enabled?() :: boolean()
  defp customer_io_enabled?() do
    case System.get_env("CUSTOMER_IO_API_KEY") do
      key when is_binary(key) -> String.length(key) > 0
      _ -> false
    end
  end
end
