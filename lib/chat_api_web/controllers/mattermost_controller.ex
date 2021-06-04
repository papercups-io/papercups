defmodule ChatApiWeb.MattermostController do
  use ChatApiWeb, :controller

  alias ChatApi.{Mattermost, Messages, Slack}
  alias ChatApi.Mattermost.MattermostAuthorization

  require Logger

  action_fallback(ChatApiWeb.FallbackController)

  @spec auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def auth(conn, %{"authorization" => authorization}) do
    Logger.info("Params from Mattermost auth: #{inspect(authorization)}")

    # TODO: verify that auth info works with Mattermost API before creating?
    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         params <- Map.merge(authorization, %{"account_id" => account_id, "user_id" => user_id}),
         {:ok, result} <- Mattermost.create_or_update_authorization!(params) do
      json(conn, %{data: %{ok: true, id: result.id}})
    else
      _ -> json(conn, %{data: %{ok: false}})
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    authorization =
      conn
      |> Pow.Plug.current_user()
      |> Map.get(:account_id)
      |> Mattermost.get_authorization_by_account()

    case authorization do
      nil ->
        json(conn, %{data: nil})

      auth ->
        json(conn, %{
          data: %{
            id: auth.id,
            created_at: auth.inserted_at,
            channel: auth.channel_name,
            team_name: auth.team_domain
          }
        })
    end
  end

  @spec channels(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def channels(conn, %{"mattermost_url" => mattermost_url, "access_token" => access_token}) do
    authorization = %MattermostAuthorization{
      access_token: access_token,
      mattermost_url: mattermost_url,
      account_id: conn.assigns.current_user.account_id,
      user_id: conn.assigns.current_user.id
    }

    # TODO: figure out the best way to handle errors here... should we just return
    # an empty list of channels if the call fails, or indicate that an error occurred?
    case Mattermost.Client.list_channels(authorization) do
      {:ok, %{body: channels}} -> json(conn, %{data: channels})
      _ -> json(conn, %{data: []})
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %MattermostAuthorization{} = auth <-
           Mattermost.get_mattermost_authorization!(id),
         {:ok, %MattermostAuthorization{}} <- Mattermost.delete_mattermost_authorization(auth) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(conn, payload) do
    Logger.debug("Payload from Mattermost webhook: #{inspect(payload)}")
    handle_event(payload)
    send_resp(conn, 200, "")
  end

  defp handle_event(%{
         "channel_id" => channel_id,
         "file_ids" => _file_ids,
         "post_id" => post_id,
         "team_domain" => _team_domain,
         "team_id" => _team_id,
         "text" => text,
         "timestamp" => timestamp,
         "token" => token,
         "user_id" => user_id
       }) do
    with %{account_id: account_id} = authorization <-
           Mattermost.find_mattermost_authorization(%{
             channel_id: channel_id,
             verification_token: token
           }),
         {:ok, %{body: %{"root_id" => root_id} = response}} <-
           Mattermost.Client.get_message(post_id, authorization),
         false <- get_in(response, ["props", "from_bot"]) == "true",
         %{conversation: conversation} <-
           Mattermost.find_mattermost_conversation_thread(%{
             mattermost_channel_id: channel_id,
             mattermost_post_root_id: root_id,
             account_id: account_id
           }) do
      text
      |> Slack.Helpers.parse_message_type_params()
      |> Map.merge(%{
        "body" => Slack.Helpers.sanitize_private_note(text),
        "conversation_id" => conversation.id,
        "account_id" => account_id,
        "source" => "mattermost",
        "sent_at" => Mattermost.Helpers.mattermost_ts_to_utc(timestamp),
        "user_id" =>
          case Mattermost.Helpers.find_matching_user(authorization, user_id) do
            nil -> conversation.assignee_id
            user -> user.id
          end
      })
      |> Messages.create_and_fetch!()
      |> Messages.Notification.broadcast_to_customer!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:webhooks)
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:conversation_reply_email)
      |> Messages.Notification.notify(:gmail)
      |> Messages.Notification.notify(:sms)
      |> Messages.Helpers.handle_post_creation_hooks()
    end
  end

  defp handle_event(payload) do
    Logger.info("Unexpected payload from Mattermost: #{inspect(payload)}")
  end
end
