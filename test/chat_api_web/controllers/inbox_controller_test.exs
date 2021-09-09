defmodule ChatApiWeb.InboxControllerTest do
  use ChatApiWeb.ConnCase, async: true
  import ChatApi.Factory
  alias ChatApi.Inboxes.Inbox

  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    is_private: true
  }
  @invalid_attrs %{
    name: nil
  }

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    inbox = insert(:inbox, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account, inbox: inbox}
  end

  describe "index" do
    test "lists all inboxes", %{
      authed_conn: authed_conn,
      inbox: inbox
    } do
      resp = get(authed_conn, Routes.inbox_path(authed_conn, :index))
      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [inbox.id]
    end
  end

  describe "show inbox" do
    test "shows inbox by id", %{
      account: account,
      authed_conn: authed_conn
    } do
      inbox = insert(:inbox, %{account: account})

      conn =
        get(
          authed_conn,
          Routes.inbox_path(authed_conn, :show, inbox.id)
        )

      assert json_response(conn, 200)["data"]
    end

    test "renders 404 when asking for another user's inbox", %{
      authed_conn: authed_conn
    } do
      # Create a new account and give it a inbox
      another_account = insert(:account)

      inbox =
        insert(:inbox, %{
          name: "Another Inbox",
          account: another_account
        })

      # Using the original session, try to delete the new account's inbox
      conn =
        get(
          authed_conn,
          Routes.inbox_path(authed_conn, :show, inbox.id)
        )

      assert json_response(conn, 404)
    end
  end

  describe "create inbox" do
    test "renders inbox when data is valid", %{
      authed_conn: authed_conn,
      account: account
    } do
      resp =
        post(authed_conn, Routes.inbox_path(authed_conn, :create),
          inbox:
            params_for(:inbox,
              account: account,
              name: "Some Inbox"
            )
        )

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.inbox_path(authed_conn, :show, id))
      account_id = account.id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "object" => "inbox",
               "name" => "Some Inbox"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn = post(authed_conn, Routes.inbox_path(authed_conn, :create), inbox: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update inbox" do
    test "renders inbox when data is valid", %{
      authed_conn: authed_conn,
      inbox: %Inbox{id: id} = inbox
    } do
      conn =
        put(authed_conn, Routes.inbox_path(authed_conn, :update, inbox), inbox: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.inbox_path(authed_conn, :show, id))
      account_id = inbox.account_id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "object" => "inbox",
               "name" => "some updated name",
               "description" => "some updated description",
               "is_private" => true
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      inbox: inbox
    } do
      conn =
        put(authed_conn, Routes.inbox_path(authed_conn, :update, inbox), inbox: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders 404 when editing another account's inbox",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a inbox
      another_account = insert(:account)

      inbox =
        insert(:inbox, %{
          name: "My Inbox",
          account: another_account
        })

      # Using the original session, try to update the new account's inbox
      conn =
        put(
          authed_conn,
          Routes.inbox_path(authed_conn, :update, inbox),
          inbox: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete inbox" do
    test "deletes chosen inbox", %{
      authed_conn: authed_conn,
      inbox: inbox
    } do
      conn =
        delete(
          authed_conn,
          Routes.inbox_path(authed_conn, :delete, inbox)
        )

      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.inbox_path(authed_conn, :show, inbox))
      end)
    end

    test "renders 404 when deleting another account's inbox",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a inbox
      another_account = insert(:account)

      inbox =
        insert(:inbox, %{
          name: "another@forwarding.co",
          account: another_account
        })

      # Using the original session, try to delete the new account's inbox
      conn =
        delete(
          authed_conn,
          Routes.inbox_path(authed_conn, :delete, inbox)
        )

      assert json_response(conn, 404)
    end
  end
end
