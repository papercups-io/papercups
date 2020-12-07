defmodule ChatApi.BrowserReplayEventsTest do
  use ChatApi.DataCase

  import ChatApi.Factory

  alias ChatApi.BrowserReplayEvents
  alias ChatApi.BrowserReplayEvents.BrowserReplayEvent

  describe "browser_replay_events" do
    @update_attrs %{event: %{"foo" => "baz"}}
    @invalid_attrs %{account_id: nil, event: nil}

    setup do
      account = insert(:account)
      browser_session = insert(:browser_session, account: account)
      browser_replay_event = insert(:browser_replay_event)

      {:ok,
       account: account,
       browser_session: browser_session,
       browser_replay_event: browser_replay_event}
    end

    test "list_browser_replay_events/0 returns all browser_replay_events",
         %{account: account} do
      insert_pair(:browser_replay_event, account: account)

      found_events = BrowserReplayEvents.list_browser_replay_events(account.id)

      assert length(found_events) == 2
    end

    test "get_browser_replay_event!/1 returns the browser_replay_event with given id",
         %{browser_replay_event: browser_replay_event} do
      found_event =
        BrowserReplayEvents.get_browser_replay_event!(browser_replay_event.id)
        |> Repo.preload([:account, :browser_session])

      assert found_event == browser_replay_event
    end

    test "create_browser_replay_event/1 with valid data creates a browser_replay_event",
         %{browser_session: browser_session} do
      assert {:ok, %BrowserReplayEvent{} = browser_replay_event} =
               BrowserReplayEvents.create_browser_replay_event(
                 params_for(:browser_replay_event,
                   browser_session: browser_session,
                   account_id: browser_session.account_id
                 )
               )

      assert browser_replay_event.event == %{"foo" => "bar"}
    end

    test "create_browser_replay_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               BrowserReplayEvents.create_browser_replay_event(@invalid_attrs)
    end

    test "update_browser_replay_event/2 with valid data updates the browser_replay_event",
         %{browser_replay_event: browser_replay_event} do
      assert {:ok, %BrowserReplayEvent{} = browser_replay_event} =
               BrowserReplayEvents.update_browser_replay_event(
                 browser_replay_event,
                 @update_attrs
               )

      assert browser_replay_event.event == %{"foo" => "baz"}
    end

    test "update_browser_replay_event/2 with invalid data returns error changeset",
         %{browser_replay_event: browser_replay_event} do
      assert {:error, %Ecto.Changeset{}} =
               BrowserReplayEvents.update_browser_replay_event(
                 browser_replay_event,
                 @invalid_attrs
               )

      assert browser_replay_event ==
               BrowserReplayEvents.get_browser_replay_event!(browser_replay_event.id)
               |> Repo.preload([:account, :browser_session])
    end

    test "delete_browser_replay_event/1 deletes the browser_replay_event",
         %{browser_replay_event: browser_replay_event} do
      assert {:ok, %BrowserReplayEvent{}} =
               BrowserReplayEvents.delete_browser_replay_event(browser_replay_event)

      assert_raise Ecto.NoResultsError, fn ->
        BrowserReplayEvents.get_browser_replay_event!(browser_replay_event.id)
      end
    end

    test "change_browser_replay_event/1 returns a browser_replay_event changeset",
         %{browser_replay_event: browser_replay_event} do
      assert %Ecto.Changeset{} =
               BrowserReplayEvents.change_browser_replay_event(browser_replay_event)
    end
  end
end
