defmodule ChatApi.SlackConversationThreadsTest do
  use ChatApi.DataCase

  alias ChatApi.SlackConversationThreads

  describe "slack_conversation_threads" do
    alias ChatApi.SlackConversationThreads.SlackConversationThread

    # TODO: fix tests
    @valid_attrs %{
      conversation_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      account_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      slack_thread_ts: "some slack_thread_ts",
      slack_channel: "some slack_channel"
    }
    @update_attrs %{
      conversation_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      account_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      slack_thread_ts: "some updated slack_thread_ts",
      slack_channel: "some updated slack_channel"
    }
    @invalid_attrs %{conversation_id: nil, slack_thread_ts: nil}

    def slack_conversation_thread_fixture(attrs \\ %{}) do
      {:ok, slack_conversation_thread} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SlackConversationThreads.create_slack_conversation_thread()

      slack_conversation_thread
    end

    test "list_slack_conversation_threads/0 returns all slack_conversation_threads" do
      slack_conversation_thread = slack_conversation_thread_fixture()

      assert SlackConversationThreads.list_slack_conversation_threads() == [
               slack_conversation_thread
             ]
    end

    test "get_slack_conversation_thread!/1 returns the slack_conversation_thread with given id" do
      slack_conversation_thread = slack_conversation_thread_fixture()

      assert SlackConversationThreads.get_slack_conversation_thread!(slack_conversation_thread.id) ==
               slack_conversation_thread
    end

    test "create_slack_conversation_thread/1 with valid data creates a slack_conversation_thread" do
      assert {:ok, %SlackConversationThread{} = slack_conversation_thread} =
               SlackConversationThreads.create_slack_conversation_thread(@valid_attrs)

      assert slack_conversation_thread.conversation_id == "some conversation_id"
      assert slack_conversation_thread.thread_ts == "some thread_ts"
    end

    test "create_slack_conversation_thread/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SlackConversationThreads.create_slack_conversation_thread(@invalid_attrs)
    end

    test "update_slack_conversation_thread/2 with valid data updates the slack_conversation_thread" do
      slack_conversation_thread = slack_conversation_thread_fixture()

      assert {:ok, %SlackConversationThread{} = slack_conversation_thread} =
               SlackConversationThreads.update_slack_conversation_thread(
                 slack_conversation_thread,
                 @update_attrs
               )

      assert slack_conversation_thread.conversation_id == "some updated conversation_id"
      assert slack_conversation_thread.thread_ts == "some updated thread_ts"
    end

    test "update_slack_conversation_thread/2 with invalid data returns error changeset" do
      slack_conversation_thread = slack_conversation_thread_fixture()

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

    test "delete_slack_conversation_thread/1 deletes the slack_conversation_thread" do
      slack_conversation_thread = slack_conversation_thread_fixture()

      assert {:ok, %SlackConversationThread{}} =
               SlackConversationThreads.delete_slack_conversation_thread(
                 slack_conversation_thread
               )

      assert_raise Ecto.NoResultsError, fn ->
        SlackConversationThreads.get_slack_conversation_thread!(slack_conversation_thread.id)
      end
    end

    test "change_slack_conversation_thread/1 returns a slack_conversation_thread changeset" do
      slack_conversation_thread = slack_conversation_thread_fixture()

      assert %Ecto.Changeset{} =
               SlackConversationThreads.change_slack_conversation_thread(
                 slack_conversation_thread
               )
    end
  end
end
