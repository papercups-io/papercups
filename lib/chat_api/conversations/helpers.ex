defmodule ChatApi.Conversations.Helpers do
  @moduledoc """
  Helper methods for Conversations context.
  """

  require Logger
  alias ChatApi.{Slack, SlackAuthorizations, SlackConversationThreads}
  alias ChatApi.Conversations.Conversation

  @spec format(Conversation.t()) :: map()
  def format(%Conversation{} = conversation),
    do: ChatApiWeb.ConversationView.render("basic.json", conversation: conversation)

  @spec broadcast_conversation_updates_to_slack(Conversation.t()) :: any()
  def broadcast_conversation_updates_to_slack(
        %Conversation{
          id: conversation_id,
          account_id: account_id,
          inbox_id: inbox_id
        } = conversation
      ) do
    # TODO: we need to ensure that the Papercups app is added to the channel manually before this can work
    with %{channel_id: channel, access_token: access_token} <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{
             type: "reply",
             inbox_id: inbox_id
           }),
         [%{slack_thread_ts: ts}] <-
           SlackConversationThreads.get_threads_by_conversation_id(conversation_id, %{
             "account_id" => account_id,
             "slack_channel" => channel
           }),
         {:ok, response} <-
           Slack.Client.retrieve_message(channel, ts, access_token),
         {:ok, %{"blocks" => blocks}} <- Slack.Extractor.extract_slack_message(response) do
      updated_blocks =
        Enum.map(blocks, fn block ->
          case block do
            %{"fields" => [_ | _] = fields} ->
              Map.merge(block, %{
                "fields" =>
                  Slack.Helpers.update_fields_with_conversation_status(fields, conversation)
              })

            %{"type" => "actions"} ->
              Map.merge(block, %{
                "elements" =>
                  Slack.Helpers.update_action_elements_with_conversation_status(conversation)
              })

            _ ->
              block
          end
        end)

      Slack.Client.update_message(channel, ts, %{"blocks" => updated_blocks}, access_token)
    end
  end

  # TODO: deprecate/remove code below?

  @spec send_conversation_state_update(Conversation.t(), map()) ::
          {:ok, String.t()} | {:error, String.t()}
  def send_conversation_state_update(_conversation, state) do
    case get_conversation_state_message(state) do
      nil ->
        # TODO: should we use an atom here (e.g. :invalid_state),
        # or a more descriptive string (e.g. "Invalid state: #{inspect(state)}")?
        {:error, "state_invalid"}

      conversation_state_message ->
        Logger.info("Would have sent conversation update: #{inspect(conversation_state_message)}")
        # # TODO: disabling this for now
        # Slack.send_conversation_message_alert(
        #   conversation.id,
        #   conversation_state_message,
        #   type: :conversation_update
        # )

        {:ok, conversation_state_message}
    end
  end

  @spec send_multiple_archived_updates([Conversation.t()]) :: list()
  def send_multiple_archived_updates(conversations) do
    state = %{"state" => "archived"}

    Enum.map(conversations, fn conversation ->
      send_conversation_state_update(conversation, state)
    end)
  end

  @spec get_conversation_state_message(map()) :: String.t() | nil
  defp get_conversation_state_message(state) do
    case state do
      %{"status" => "open"} ->
        ":outbox_tray: This conversation has been reopened."

      %{"status" => "closed"} ->
        ":white_check_mark: This conversation has been closed."

      %{"state" => "archived"} ->
        ":file_cabinet: This conversation has been archived."

      %{"state" => "deleted"} ->
        ":wastebasket: This conversation has been deleted."

      %{"priority" => "priority"} ->
        ":star: This conversation has been prioritized."

      %{"priority" => "not_priority"} ->
        ":ok_hand: This conversation has been de-prioritized."

      _ ->
        nil
    end
  end
end
