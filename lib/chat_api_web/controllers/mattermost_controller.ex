defmodule ChatApiWeb.MattermostController do
  use ChatApiWeb, :controller

  alias ChatApi.{Mattermost, Messages}

  require Logger

  action_fallback(ChatApiWeb.FallbackController)

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, params) do
    Logger.info("Params from Mattermost OAuth: #{inspect(params)}")
    # TODO: implement me!
    json(conn, %{data: nil})
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    # TODO: implement me!
    # (See implementation in Slack controller - this will look similar)
    json(conn, %{data: nil})
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => _id}) do
    # TODO: implement me!
    # (See implementation in Slack controller - this will look similar)
    send_resp(conn, :no_content, "")
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
      %{
        "body" => text,
        "conversation_id" => conversation.id,
        "account_id" => account_id,
        "source" => "mattermost",
        "sent_at" => Mattermost.Helpers.mattermost_ts_to_utc(timestamp),
        "user_id" =>
          case Mattermost.Helpers.find_matching_user(authorization, user_id) do
            nil -> conversation.assignee_id
            user -> user.id
          end
      }
      |> Messages.create_and_fetch!()
      |> Messages.Notification.broadcast_to_customer!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:webhooks)
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:conversation_reply_email)
      |> Messages.Helpers.handle_post_creation_conversation_updates()
    end
  end

  defp handle_event(payload) do
    Logger.info("Unexpected payload from Mattermost: #{inspect(payload)}")
  end
end
