defmodule ChatApi.SlackConversationThreadsTest do
  use ChatApi.DataCase, async: true

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

    def valid_create_attrs do
      account = account_fixture()
      customer = customer_fixture(account)
      conversation = conversation_fixture(account, customer)

      Enum.into(@valid_attrs, %{account_id: account.id, conversation_id: conversation.id})
    end

    setup do
      account = account_fixture()
      customer = customer_fixture(account)
      conversation = conversation_fixture(account, customer)
      slack_conversation_thread = slack_conversation_thread_fixture(conversation)

      {:ok, conversation: conversation, slack_conversation_thread: slack_conversation_thread}
    end

    test "list_slack_conversation_threads/0 returns all slack_conversation_threads", %{
      slack_conversation_thread: slack_conversation_thread
    } do
      assert SlackConversationThreads.list_slack_conversation_threads() == [
               slack_conversation_thread
             ]
    end

    test "get_slack_conversation_thread!/1 returns the slack_conversation_thread with given id",
         %{
           slack_conversation_thread: slack_conversation_thread
         } do
      assert SlackConversationThreads.get_slack_conversation_thread!(slack_conversation_thread.id) ==
               slack_conversation_thread
    end

    test "create_slack_conversation_thread/1 with valid data creates a slack_conversation_thread" do
      assert {:ok, %SlackConversationThread{} = slack_conversation_thread} =
               SlackConversationThreads.create_slack_conversation_thread(valid_create_attrs())

      assert slack_conversation_thread.slack_channel == "some slack_channel"
      assert slack_conversation_thread.slack_thread_ts == "some slack_thread_ts"
    end

    test "create_slack_conversation_thread/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SlackConversationThreads.create_slack_conversation_thread(@invalid_attrs)
    end

    test "update_slack_conversation_thread/2 with valid data updates the slack_conversation_thread",
         %{
           slack_conversation_thread: slack_conversation_thread
         } do
      assert {:ok, %SlackConversationThread{} = slack_conversation_thread} =
               SlackConversationThreads.update_slack_conversation_thread(
                 slack_conversation_thread,
                 @update_attrs
               )

      assert slack_conversation_thread.slack_channel == "some updated slack_channel"
      assert slack_conversation_thread.slack_thread_ts == "some updated slack_thread_ts"
    end

    test "update_slack_conversation_thread/2 with invalid data returns error changeset",
         %{
           slack_conversation_thread: slack_conversation_thread
         } do
      assert {:error, %Ecto.Changeset{}} =
               SlackConversationThreads.update_slack_conversation_thread(
                 slack_conversation_thread,
                 @invalid_attrs
               )

      assert slack_conversation_thread ==
               SlackConversationThreads.get_slack_conversation_thread!(
                 slack_conversation_thread.id
               )
    end

    test "delete_slack_conversation_thread/1 deletes the slack_conversation_thread",
         %{
           slack_conversation_thread: slack_conversation_thread
         } do
      assert {:ok, %SlackConversationThread{}} =
               SlackConversationThreads.delete_slack_conversation_thread(
                 slack_conversation_thread
               )

      assert_raise Ecto.NoResultsError, fn ->
        SlackConversationThreads.get_slack_conversation_thread!(slack_conversation_thread.id)
      end
    end

    test "change_slack_conversation_thread/1 returns a slack_conversation_thread changeset",
         %{
           slack_conversation_thread: slack_conversation_thread
         } do
      assert %Ecto.Changeset{} =
               SlackConversationThreads.change_slack_conversation_thread(
                 slack_conversation_thread
               )
    end

    test "get_by_slack_thread_ts/2 finds a slack_conversation_thread by thread_ts and channel",
         %{
           conversation: conversation
         } do
      slack_conversation_thread =
        slack_conversation_thread_fixture(conversation, %{
          slack_thread_ts: "ts1",
          slack_channel: "ch1"
        })

      result = SlackConversationThreads.get_by_slack_thread_ts("ts1", "ch1")

      assert result.id == slack_conversation_thread.id
      refute SlackConversationThreads.get_by_slack_thread_ts("ts2", "ch1")
      refute SlackConversationThreads.get_by_slack_thread_ts("ts1", "ch2")
    end

    test "get_thread_by_conversation_id/2 finds a slack_conversation_thread by conversation_id and channel",
         %{
           conversation: conversation
         } do
      slack_conversation_thread =
        slack_conversation_thread_fixture(conversation, %{
          slack_channel: "ch1"
        })

      result = SlackConversationThreads.get_thread_by_conversation_id(conversation.id, "ch1")

      assert result.id == slack_conversation_thread.id
      refute SlackConversationThreads.get_thread_by_conversation_id(conversation.id, "ch2")
    end
  end
end
