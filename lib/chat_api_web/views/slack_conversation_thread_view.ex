defmodule ChatApiWeb.SlackConversationThreadView do
  use ChatApiWeb, :view
  alias ChatApiWeb.SlackConversationThreadView

  def render("index.json", %{slack_conversation_threads: slack_conversation_threads}) do
    %{
      data:
        render_many(
          slack_conversation_threads,
          SlackConversationThreadView,
          "slack_conversation_thread.json"
        )
    }
  end

  def render("show.json", %{slack_conversation_thread: slack_conversation_thread}) do
    %{
      data:
        render_one(
          slack_conversation_thread,
          SlackConversationThreadView,
          "slack_conversation_thread.json"
        )
    }
  end

  def render("slack_conversation_thread.json", %{
        slack_conversation_thread: slack_conversation_thread
      }) do
    %{
      id: slack_conversation_thread.id,
      object: "slack_conversation_thread",
      account_id: slack_conversation_thread.account_id,
      conversation_id: slack_conversation_thread.conversation_id,
      created_at: slack_conversation_thread.inserted_at,
      updated_at: slack_conversation_thread.updated_at,
      slack_channel: slack_conversation_thread.slack_channel,
      slack_thread_ts: slack_conversation_thread.slack_thread_ts,
      # Computed params
      permalink: slack_conversation_thread.permalink,
      slack_channel_name: slack_conversation_thread.slack_channel_name
    }
  end
end
