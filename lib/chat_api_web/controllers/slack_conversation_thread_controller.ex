defmodule ChatApiWeb.SlackConversationThreadController do
  use ChatApiWeb, :controller
  require Logger
  alias ChatApi.SlackConversationThreads

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{current_user: %{account_id: account_id}}} = conn, %{
        "conversation_id" => conversation_id
      }) do
    slack_conversation_threads =
      SlackConversationThreads.list_slack_conversation_threads_by_account(account_id, %{
        "conversation_id" => conversation_id
      })

    render(conn, "index.json", slack_conversation_threads: slack_conversation_threads)
  end
end
