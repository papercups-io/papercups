defmodule ChatApi.BrowserReplayEventsTest do
  use ChatApi.DataCase

  alias ChatApi.BrowserReplayEvents

  describe "browser_replay_events" do
    alias ChatApi.BrowserReplayEvents.BrowserReplayEvent

    @valid_attrs %{event: %{"foo" => "bar"}}
    @update_attrs %{event: %{"foo" => "baz"}}
    @invalid_attrs %{account_id: nil, event: nil}

    setup do
      account = account_fixture()
      browser_session = browser_session_fixture(account)

      {:ok, account: account, browser_session: browser_session}
    end

    test "list_browser_replay_events/0 returns all browser_replay_events", %{
      browser_session: browser_session
    } do
      browser_replay_event = browser_replay_event_fixture(browser_session)

      assert BrowserReplayEvents.list_browser_replay_events(browser_session.account_id) == [
               browser_replay_event
             ]
    end

    test "get_browser_replay_event!/1 returns the browser_replay_event with given id", %{
      browser_session: browser_session
    } do
      browser_replay_event = browser_replay_event_fixture(browser_session)

      assert BrowserReplayEvents.get_browser_replay_event!(browser_replay_event.id) ==
               browser_replay_event
    end

    test "create_browser_replay_event/1 with valid data creates a browser_replay_event", %{
      browser_session: browser_session
    } do
      attrs =
        Map.merge(@valid_attrs, %{
          browser_session_id: browser_session.id,
          account_id: browser_session.account_id
        })

      assert {:ok, %BrowserReplayEvent{} = browser_replay_event} =
               BrowserReplayEvents.create_browser_replay_event(attrs)

      assert browser_replay_event.event == %{"foo" => "bar"}
    end

    test "create_browser_replay_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               BrowserReplayEvents.create_browser_replay_event(@invalid_attrs)
    end

    test "update_browser_replay_event/2 with valid data updates the browser_replay_event", %{
      browser_session: browser_session
    } do
      browser_replay_event = browser_replay_event_fixture(browser_session)

      assert {:ok, %BrowserReplayEvent{} = browser_replay_event} =
               BrowserReplayEvents.update_browser_replay_event(
                 browser_replay_event,
                 @update_attrs
               )

      assert browser_replay_event.event == %{"foo" => "baz"}
    end

    test "update_browser_replay_event/2 with invalid data returns error changeset", %{
      browser_session: browser_session
    } do
      browser_replay_event = browser_replay_event_fixture(browser_session)

      assert {:error, %Ecto.Changeset{}} =
               BrowserReplayEvents.update_browser_replay_event(
                 browser_replay_event,
                 @invalid_attrs
               )

      assert browser_replay_event ==
               BrowserReplayEvents.get_browser_replay_event!(browser_replay_event.id)
    end

    test "delete_browser_replay_event/1 deletes the browser_replay_event", %{
      browser_session: browser_session
    } do
      browser_replay_event = browser_replay_event_fixture(browser_session)

      assert {:ok, %BrowserReplayEvent{}} =
               BrowserReplayEvents.delete_browser_replay_event(browser_replay_event)

      assert_raise Ecto.NoResultsError, fn ->
        BrowserReplayEvents.get_browser_replay_event!(browser_replay_event.id)
      end
    end

    test "change_browser_replay_event/1 returns a browser_replay_event changeset", %{
      browser_session: browser_session
    } do
      browser_replay_event = browser_replay_event_fixture(browser_session)

      assert %Ecto.Changeset{} =
               BrowserReplayEvents.change_browser_replay_event(browser_replay_event)
    end
  end
end
