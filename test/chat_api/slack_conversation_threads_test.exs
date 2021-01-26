defmodule ChatApi.SlackConversationThreadsTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  import Mock
  alias ChatApi.SlackConversationThreads

  describe "slack_conversation_threads" do
    alias ChatApi.SlackConversationThreads.SlackConversationThread

    @valid_attrs %{
      slack_thread_ts: "some slack_thread_ts",
      slack_channel: "some slack_channel"
    }
    @update_attrs %{
      slack_thread_ts: "some updated slack_thread_ts",
      slack_channel: "some updated slack_channel"
    }
    @invalid_attrs %{slack_thread_ts: nil, slack_channel: nil}

    setup do
      account = insert(:account)
      conversation = insert(:conversation, account: account)

      slack_conversation_thread =
        insert(:slack_conversation_thread, conversation: conversation, account: account)

      {:ok,
       account: account,
       conversation: conversation,
       slack_conversation_thread: slack_conversation_thread}
    end

    test "list_slack_conversation_threads/0 returns all slack_conversation_threads",
         %{slack_conversation_thread: slack_conversation_thread} do
      thread_ids =
        SlackConversationThreads.list_slack_conversation_threads()
        |> Enum.map(& &1.id)

      assert thread_ids == [slack_conversation_thread.id]
    end

    test "list_slack_conversation_threads_by_account/2 returns all slack_conversation_threads for the account",
         %{account: account, slack_conversation_thread: slack_conversation_thread} do
      other_conversation = insert(:conversation)

      _other_slack_conversation_thread =
        insert(:slack_conversation_thread, conversation: other_conversation)

      thread_ids =
        SlackConversationThreads.list_slack_conversation_threads_by_account(account.id)
        |> Enum.map(& &1.id)

      assert thread_ids == [slack_conversation_thread.id]
    end

    test "list_slack_conversation_threads_by_account/2 can filter by conversation_id",
         %{
           account: account,
           conversation: conversation,
           slack_conversation_thread: slack_conversation_thread
         } do
      thread_ids =
        SlackConversationThreads.list_slack_conversation_threads_by_account(account.id, %{
          "conversation_id" => conversation.id
        })
        |> Enum.map(& &1.id)

      assert thread_ids == [slack_conversation_thread.id]

      other_conversation = insert(:conversation)

      assert [] =
               SlackConversationThreads.list_slack_conversation_threads_by_account(account.id, %{
                 "conversation_id" => other_conversation.id
               })
    end

    test "list_slack_conversation_threads_by_account/2 includes the permalink if possible",
         %{
           account: account,
           conversation: conversation,
           slack_conversation_thread: slack_conversation_thread
         } do
      insert(:slack_authorization, account: account, type: "support")
      permalink = "https://slack.com/archives/C12345"
      slack_channel_name = "support"

      with_mock ChatApi.Slack.Client,
        get_message_permalink: fn _, _, _ ->
          {:ok, %{body: %{"permalink" => permalink}}}
        end,
        retrieve_channel_info: fn _, _ ->
          {:ok, %{body: %{"channel" => %{"name" => slack_channel_name}}}}
        end do
        assert [
                 %{
                   id: slack_conversation_thread_id,
                   permalink: ^permalink,
                   slack_channel_name: ^slack_channel_name
                 }
               ] =
                 SlackConversationThreads.list_slack_conversation_threads_by_account(
                   account.id,
                   %{
                     "conversation_id" => conversation.id
                   }
                 )

        assert slack_conversation_thread.id == slack_conversation_thread_id
      end
    end

    test "list_slack_conversation_threads_by_account/2 returns nil for dynamic fields if they fail",
         %{
           account: account,
           conversation: conversation,
           slack_conversation_thread: slack_conversation_thread
         } do
      insert(:slack_authorization, account: account, type: "support")

      with_mock ChatApi.Slack.Client,
        get_message_permalink: fn _, _, _ ->
          {:error, "Something went wrong"}
        end,
        retrieve_channel_info: fn _, _ ->
          {:error, "Something went wrong"}
        end do
        assert [
                 %{
                   id: slack_conversation_thread_id,
                   permalink: nil,
                   slack_channel_name: nil
                 }
               ] =
                 SlackConversationThreads.list_slack_conversation_threads_by_account(
                   account.id,
                   %{
                     "conversation_id" => conversation.id
                   }
                 )

        assert slack_conversation_thread.id == slack_conversation_thread_id
      end
    end

    test "get_slack_conversation_thread!/1 returns the slack_conversation_thread with given id",
         %{slack_conversation_thread: slack_conversation_thread} do
      found_slack_conversation_thread =
        SlackConversationThreads.get_slack_conversation_thread!(slack_conversation_thread.id)

      assert found_slack_conversation_thread.id == slack_conversation_thread.id
    end

    test "create_slack_conversation_thread/1 with valid data creates a slack_conversation_thread" do
      assert {:ok, %SlackConversationThread{} = slack_conversation_thread} =
               SlackConversationThreads.create_slack_conversation_thread(
                 params_with_assocs(:slack_conversation_thread, @valid_attrs)
               )

      assert slack_conversation_thread.slack_channel == @valid_attrs.slack_channel
      assert slack_conversation_thread.slack_thread_ts == @valid_attrs.slack_thread_ts
    end

    test "create_slack_conversation_thread/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SlackConversationThreads.create_slack_conversation_thread(@invalid_attrs)
    end

    test "update_slack_conversation_thread/2 with valid data updates the slack_conversation_thread",
         %{slack_conversation_thread: slack_conversation_thread} do
      assert {:ok, %SlackConversationThread{} = slack_conversation_thread} =
               SlackConversationThreads.update_slack_conversation_thread(
                 slack_conversation_thread,
                 @update_attrs
               )

      assert slack_conversation_thread.slack_channel == @update_attrs.slack_channel
      assert slack_conversation_thread.slack_thread_ts == @update_attrs.slack_thread_ts
    end

    test "update_slack_conversation_thread/2 with invalid data returns error changeset",
         %{slack_conversation_thread: slack_conversation_thread} do
      assert {:error, %Ecto.Changeset{}} =
               SlackConversationThreads.update_slack_conversation_thread(
                 slack_conversation_thread,
                 @invalid_attrs
               )

      found_slack_conversation_thread =
        SlackConversationThreads.get_slack_conversation_thread!(slack_conversation_thread.id)
        |> Map.drop([:account, :conversation])

      assert Map.drop(slack_conversation_thread, [:account, :conversation]) ==
               found_slack_conversation_thread
    end

    test "delete_slack_conversation_thread/1 deletes the slack_conversation_thread",
         %{slack_conversation_thread: slack_conversation_thread} do
      assert {:ok, %SlackConversationThread{}} =
               SlackConversationThreads.delete_slack_conversation_thread(
                 slack_conversation_thread
               )

      assert_raise Ecto.NoResultsError, fn ->
        SlackConversationThreads.get_slack_conversation_thread!(slack_conversation_thread.id)
      end
    end

    test "change_slack_conversation_thread/1 returns a slack_conversation_thread changeset",
         %{slack_conversation_thread: slack_conversation_thread} do
      assert %Ecto.Changeset{} =
               SlackConversationThreads.change_slack_conversation_thread(
                 slack_conversation_thread
               )
    end

    test "get_by_slack_thread_ts/2 finds a slack_conversation_thread by thread_ts and channel",
         %{conversation: conversation} do
      slack_conversation_thread =
        insert(:slack_conversation_thread,
          conversation: conversation,
          slack_thread_ts: "ts1",
          slack_channel: "ch1"
        )

      result = SlackConversationThreads.get_by_slack_thread_ts("ts1", "ch1")

      assert result.id == slack_conversation_thread.id
      refute SlackConversationThreads.get_by_slack_thread_ts("ts2", "ch1")
      refute SlackConversationThreads.get_by_slack_thread_ts("ts1", "ch2")
    end

    test "get_thread_by_conversation_id/2 finds a slack_conversation_thread by conversation_id and channel",
         %{conversation: conversation} do
      slack_conversation_thread =
        insert(:slack_conversation_thread,
          conversation: conversation,
          slack_channel: "ch1"
        )

      result = SlackConversationThreads.get_thread_by_conversation_id(conversation.id, "ch1")

      assert result.id == slack_conversation_thread.id
      refute SlackConversationThreads.get_thread_by_conversation_id(conversation.id, "ch2")
    end

    test "get_threads_by_conversation_id/2 finds slack_conversation_threads by conversation",
         %{conversation: conversation} do
      insert(:slack_conversation_thread, conversation: conversation, slack_channel: "ch1")
      insert(:slack_conversation_thread, conversation: conversation, slack_channel: "ch2")

      slack_channels =
        SlackConversationThreads.get_threads_by_conversation_id(conversation.id)
        |> Enum.map(& &1.slack_channel)

      assert Enum.member?(slack_channels, "ch1")
      assert Enum.member?(slack_channels, "ch2")
    end

    test "exists?/1 checks if a thread exists",
         %{conversation: conversation} do
      channel = "ch1"
      ts = "ts123"

      refute SlackConversationThreads.exists?(%{
               "slack_channel" => channel,
               "slack_thread_ts" => ts
             })

      insert(:slack_conversation_thread,
        conversation: conversation,
        slack_channel: channel,
        slack_thread_ts: ts
      )

      assert SlackConversationThreads.exists?(%{
               "slack_channel" => channel,
               "slack_thread_ts" => ts
             })
    end
  end
end
