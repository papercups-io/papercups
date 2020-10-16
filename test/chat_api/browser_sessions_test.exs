defmodule ChatApi.BrowserSessionsTest do
  use ChatApi.DataCase

  alias ChatApi.BrowserSessions

  describe "browser_sessions" do
    alias ChatApi.BrowserSessions.BrowserSession

    @valid_attrs %{
      finished_at: "2010-04-17T14:00:00Z",
      metadata: %{},
      started_at: "2010-04-17T14:00:00Z"
    }
    @update_attrs %{
      finished_at: "2011-05-18T15:01:01Z",
      metadata: %{},
      started_at: "2011-05-18T15:01:01Z"
    }
    @invalid_attrs %{
      account_id: nil,
      customer_id: nil,
      finished_at: nil,
      metadata: nil,
      started_at: nil
    }

    setup do
      account = account_fixture()

      {:ok, account: account}
    end

    test "list_browser_sessions/0 returns all browser_sessions", %{account: account} do
      browser_session = browser_session_fixture(account)
      sessions = BrowserSessions.list_browser_sessions(account.id)
      assert Enum.map(sessions, & &1.id) == [browser_session.id]
    end

    test "get_browser_session!/1 returns the browser_session with given id", %{account: account} do
      browser_session = browser_session_fixture(account)
      assert BrowserSessions.get_browser_session!(browser_session.id) == browser_session
    end

    test "create_browser_session/1 with valid data creates a browser_session", %{account: account} do
      attrs = Map.merge(@valid_attrs, %{account_id: account.id})

      assert {:ok, %BrowserSession{} = browser_session} =
               BrowserSessions.create_browser_session(attrs)

      assert browser_session.finished_at ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")

      assert browser_session.metadata == %{}

      assert browser_session.started_at ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
    end

    test "create_browser_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = BrowserSessions.create_browser_session(@invalid_attrs)
    end

    test "update_browser_session/2 with valid data updates the browser_session", %{
      account: account
    } do
      browser_session = browser_session_fixture(account)

      assert {:ok, %BrowserSession{} = browser_session} =
               BrowserSessions.update_browser_session(browser_session, @update_attrs)

      assert browser_session.finished_at ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")

      assert browser_session.metadata == %{}

      assert browser_session.started_at ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
    end

    test "update_browser_session/2 with invalid data returns error changeset", %{account: account} do
      browser_session = browser_session_fixture(account)

      assert {:error, %Ecto.Changeset{}} =
               BrowserSessions.update_browser_session(browser_session, @invalid_attrs)

      assert browser_session == BrowserSessions.get_browser_session!(browser_session.id)
    end

    test "delete_browser_session/1 deletes the browser_session", %{account: account} do
      browser_session = browser_session_fixture(account)
      assert {:ok, %BrowserSession{}} = BrowserSessions.delete_browser_session(browser_session)

      assert_raise Ecto.NoResultsError, fn ->
        BrowserSessions.get_browser_session!(browser_session.id)
      end
    end

    test "change_browser_session/1 returns a browser_session changeset", %{account: account} do
      browser_session = browser_session_fixture(account)
      assert %Ecto.Changeset{} = BrowserSessions.change_browser_session(browser_session)
    end
  end
end
