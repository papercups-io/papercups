defmodule ChatApiWeb.GithubController do
  use ChatApiWeb, :controller

  alias ChatApi.Github
  alias ChatApi.Github.GithubAuthorization

  require Logger

  action_fallback(ChatApiWeb.FallbackController)

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code}) do
    Logger.debug("Code from Github oauth: #{inspect(code)}")

    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         {:ok,
          %{body: %{"access_token" => access_token, "scope" => scope, "token_type" => token_type}}} <-
           Github.Client.get_access_token(code),
         {:ok, result} <-
           Github.create_or_update_authorization(%{
             account_id: account_id,
             user_id: user_id,
             access_token: access_token,
             scope: scope,
             token_type: token_type
           }) do
      json(conn, %{data: %{ok: true, id: result.id}})
    end
  end

  def oauth(conn, %{"setup_action" => "install", "installation_id" => installation_id}) do
    # TODO: generate the access token/refresh token using the `installation_id` plus the generated JWT
    Logger.debug("Setting up authorization for Github installation #{inspect(installation_id)}")

    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         {:ok, %{body: %{"token" => access_token, "expires_at" => expires_at} = metadata}} <-
           Github.Client.generate_installation_access_token(installation_id),
         {:ok, result} <-
           Github.create_or_update_authorization(%{
             account_id: account_id,
             user_id: user_id,
             access_token: access_token,
             access_token_expires_at: expires_at,
             github_installation_id: installation_id,
             metadata: metadata
           }) do
      json(conn, %{data: %{ok: true, id: result.id}})
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    authorization =
      conn
      |> Pow.Plug.current_user()
      |> Map.get(:account_id)
      |> Github.get_authorization_by_account()

    case authorization do
      nil ->
        json(conn, %{data: nil})

      auth ->
        json(conn, %{
          data: %{
            id: auth.id,
            created_at: auth.inserted_at,
            token_type: auth.token_type,
            scope: auth.scope
          }
        })
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %GithubAuthorization{} = auth <-
           Github.get_github_authorization!(id),
         {:ok, %GithubAuthorization{}} <- Github.delete_github_authorization(auth) do
      {:ok, _} =
        case auth.github_installation_id do
          nil -> {:ok, nil}
          installation_id -> Github.Client.delete_installation(installation_id)
        end

      send_resp(conn, :no_content, "")
    end
  end

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(conn, payload) do
    conn
    |> get_req_header("x-github-event")
    |> List.first()
    |> handle_event(payload)

    # Just respond with a 200 no matter what for now
    send_resp(conn, 200, "")
  end

  defp handle_event(
         "installation",
         %{"action" => "created", "installation" => installation} = payload
       ) do
    # TODO: handle new installation added (create new github_authorization record)
    Logger.debug(
      "Handling new Github installation event: #{inspect(payload)} (installation #{
        inspect(installation)
      })"
    )
  end

  defp handle_event(
         "installation",
         %{
           "action" => "deleted",
           "installation" => %{"id" => installation_id} = installation
         } = _payload
       ) do
    Logger.debug("Handling Github installation deleted event: #{inspect(installation)}")

    %{github_installation_id: Integer.to_string(installation_id)}
    |> Github.find_github_authorization()
    |> case do
      nil ->
        Logger.debug("No authorization found with installation ID #{inspect(installation_id)}")

      result ->
        Github.delete_github_authorization(result) |> IO.inspect()
    end
  end

  defp handle_event(
         "issues",
         %{
           "action" => "closed",
           "installation" => installation,
           "issue" => issue
         } = _payload
       ) do
    Logger.debug(
      "Handling `closed` event for Github issue #{inspect(issue)} (installation #{
        inspect(installation)
      })"
    )
  end

  defp handle_event(
         "issues",
         %{
           "action" => "opened",
           "installation" => installation,
           "issue" => issue
         } = _payload
       ) do
    Logger.debug(
      "Handling `opened` event for Github issue #{inspect(issue)} (installation #{
        inspect(installation)
      })"
    )
  end

  defp handle_event(
         "issue_comment",
         %{
           "action" => "created",
           "installation" => installation,
           "comment" => comment
         } = _event
       ) do
    Logger.debug(
      "Handling new Github comment event: #{inspect(comment)} (installation #{
        inspect(installation)
      })"
    )
  end

  defp handle_event(event, _payload) do
    Logger.debug("Unhandled Github webhook event: #{inspect(event)}")
  end
end
