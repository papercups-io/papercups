defmodule ChatApi.BrowserSessionsTest do
  use ChatApi.DataCase

  import ChatApi.Factory
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
      account = insert(:account)
      browser_session = insert(:browser_session, account: account)

      {:ok, account: account, browser_session: browser_session}
    end

    test "list_browser_sessions/0 returns all browser_sessions",
         %{account: account, browser_session: browser_session} do
      session_ids =
        BrowserSessions.list_browser_sessions(account.id)
        |> Enum.map(& &1.id)

      assert session_ids == [browser_session.id]
    end

    test "get_browser_session!/1 returns the browser_session with given id",
         %{browser_session: browser_session} do
      found_session = BrowserSessions.get_browser_session!(browser_session.id)

      assert is_struct(found_session)
      assert found_session.id == browser_session.id
    end

    test "create_browser_session/1 with valid data creates a browser_session", %{account: account} do
      attrs = Map.merge(@valid_attrs, %{account_id: account.id})

      assert {:ok, %BrowserSession{} = browser_session} =
               params_for(:browser_session, attrs)
               |> BrowserSessions.create_browser_session()

      assert browser_session.finished_at ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")

      assert browser_session.metadata == %{}

      assert browser_session.started_at ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
    end

    test "create_browser_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = BrowserSessions.create_browser_session(@invalid_attrs)
    end

    test "update_browser_session/2 with valid data updates the browser_session",
         %{browser_session: browser_session} do
      {:ok, %BrowserSession{} = browser_session} =
        BrowserSessions.update_browser_session(browser_session, @update_attrs)

      assert {:ok, %BrowserSession{} = browser_session} =
               BrowserSessions.update_browser_session(browser_session, @update_attrs)

      assert browser_session.finished_at ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")

      assert browser_session.metadata == %{}

      assert browser_session.started_at ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
    end

    test "update_browser_session/2 with invalid data returns error changeset",
         %{browser_session: browser_session} do
      assert {:error, %Ecto.Changeset{}} =
               BrowserSessions.update_browser_session(browser_session, @invalid_attrs)
    end

    test "delete_browser_session/1 deletes the browser_session",
         %{browser_session: browser_session} do
      assert {:ok, %BrowserSession{}} = BrowserSessions.delete_browser_session(browser_session)

      assert_raise Ecto.NoResultsError, fn ->
        BrowserSessions.get_browser_session!(browser_session.id)
      end
    end

    test "change_browser_session/1 returns a browser_session changeset",
         %{browser_session: browser_session} do
      assert %Ecto.Changeset{} = BrowserSessions.change_browser_session(browser_session)
    end
  end
end
