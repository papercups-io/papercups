defmodule ChatApiWeb.GoogleController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Google
  alias ChatApi.Google.GoogleAuthorization

  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t()
  @doc """
  This action is reached via `/api/google/oauth` is the the callback URL that
  Google's OAuth2 provider will redirect the user back to with a `code` that will
  be used to request an access token. The access token will then be used to
  access protected resources on behalf of the user.
  """
  def callback(conn, %{"code" => code} = params) do
    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user do
      type =
        case Map.get(params, "state") do
          state when state in ["personal", "support", "sheets"] -> state
          _ -> nil
        end

      client = Google.Auth.get_token!(code: code, redirect_uri: get_redirect_uri(type))
      Logger.debug("Gmail access token: #{inspect(client.token)}")
      scope = client.token.other_params["scope"] || params["scope"] || ""

      client_type =
        cond do
          String.contains?(scope, "spreadsheets") -> "sheets"
          String.contains?(scope, "gmail") -> "gmail"
          true -> raise "Unrecognized scope: #{scope}"
        end

      case Google.create_or_update_authorization(account_id, %{
             account_id: account_id,
             user_id: user_id,
             access_token: client.token.access_token,
             refresh_token: client.token.refresh_token,
             token_type: client.token.token_type,
             expires_at: client.token.expires_at,
             scope: scope,
             client: client_type,
             type: type
           }) do
        {:ok, auth} ->
          if should_enable_gmail_sync?(auth),
            do: enqueue_enabling_gmail_sync(account_id)

          json(conn, %{data: %{ok: true}})

        error ->
          Logger.error("Error saving sheets auth: #{inspect(error)}")

          json(conn, %{data: %{ok: false}})
      end
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, %{"client" => client} = params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      filters =
        case Map.get(params, "type") do
          "personal" -> %{client: client, type: "personal"}
          "support" -> %{client: client, type: "support"}
          "sheets" -> %{client: client, type: "sheets"}
          _ -> %{client: client}
        end

      case Google.get_authorization_by_account(account_id, filters) do
        nil ->
          json(conn, %{data: nil})

        auth ->
          json(conn, %{
            data: %{
              id: auth.id,
              created_at: auth.inserted_at,
              account_id: auth.account_id,
              user_id: auth.user_id,
              scope: auth.scope
            }
          })
      end
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, %{"client" => client} = params) do
    scope =
      case client do
        "sheets" -> "https://www.googleapis.com/auth/spreadsheets"
        "gmail" -> "https://www.googleapis.com/auth/gmail.modify"
        _ -> raise "Unrecognized client: #{client}"
      end

    redirect(conn,
      external:
        Google.Auth.authorize_url!(
          scope: scope,
          prompt: "consent",
          access_type: "offline",
          state: Map.get(params, "type"),
          redirect_uri: get_redirect_uri(params)
        )
    )
  end

  @spec auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def auth(conn, %{"client" => client} = params) do
    scope =
      case client do
        "sheets" -> "https://www.googleapis.com/auth/spreadsheets"
        "gmail" -> "https://www.googleapis.com/auth/gmail.modify"
        _ -> raise "Unrecognized client: #{client}"
      end

    url =
      Google.Auth.authorize_url!(
        scope: scope,
        prompt: "consent",
        access_type: "offline",
        state: Map.get(params, "type"),
        redirect_uri: get_redirect_uri(params)
      )

    json(conn, %{data: %{url: url}})
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %GoogleAuthorization{} = auth <-
           Google.get_google_authorization!(id),
         {:ok, %GoogleAuthorization{}} <- Google.delete_google_authorization(auth) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec get_redirect_uri(map() | binary()) :: String.t() | nil
  defp get_redirect_uri(type) when is_binary(type) do
    default_redirect_uri = System.get_env("PAPERCUPS_GOOGLE_REDIRECT_URI")

    case type do
      "support" ->
        System.get_env("PAPERCUPS_SUPPORT_GMAIL_REDIRECT_URI", default_redirect_uri)

      "personal" ->
        System.get_env("PAPERCUPS_PERSONAL_GMAIL_REDIRECT_URI", default_redirect_uri)

      _ ->
        default_redirect_uri
    end
  end

  defp get_redirect_uri(params) when is_map(params),
    do: params |> Map.get("type") |> get_redirect_uri()

  defp get_redirect_uri(_), do: System.get_env("PAPERCUPS_GOOGLE_REDIRECT_URI")

  @spec should_enable_gmail_sync?(GoogleAuthorization.t()) :: boolean()
  defp should_enable_gmail_sync?(%GoogleAuthorization{client: "gmail", type: "support"}), do: true
  defp should_enable_gmail_sync?(_), do: false

  @spec enqueue_enabling_gmail_sync(binary()) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
  defp enqueue_enabling_gmail_sync(account_id) do
    %{account_id: account_id}
    |> ChatApi.Workers.EnableGmailInboxSync.new()
    |> Oban.insert()
  end
end
