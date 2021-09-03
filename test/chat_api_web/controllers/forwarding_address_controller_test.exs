defmodule ChatApiWeb.ForwardingAddressControllerTest do
  use ChatApiWeb.ConnCase, async: true
  import ChatApi.Factory
  alias ChatApi.ForwardingAddresses.ForwardingAddress

  @update_attrs %{
    forwarding_email_address: "updated@forwarding.com",
    source_email_address: "updated@source.com",
    description: "some updated description",
    state: "some updated state"
  }
  @invalid_attrs %{
    forwarding_email_address: nil
  }

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    forwarding_address = insert(:forwarding_address, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok,
     conn: conn,
     authed_conn: authed_conn,
     account: account,
     forwarding_address: forwarding_address}
  end

  describe "index" do
    test "lists all forwarding addresses", %{
      authed_conn: authed_conn,
      forwarding_address: forwarding_address
    } do
      resp = get(authed_conn, Routes.forwarding_address_path(authed_conn, :index))
      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [forwarding_address.id]
    end
  end

  describe "show forwarding_address" do
    test "shows forwarding_address by id", %{
      account: account,
      authed_conn: authed_conn
    } do
      forwarding_address = insert(:forwarding_address, %{account: account})

      conn =
        get(
          authed_conn,
          Routes.forwarding_address_path(authed_conn, :show, forwarding_address.id)
        )

      assert json_response(conn, 200)["data"]
    end

    test "renders 404 when asking for another user's forwarding_address", %{
      authed_conn: authed_conn
    } do
      # Create a new account and give it a forwarding_address
      another_account = insert(:account)

      forwarding_address =
        insert(:forwarding_address, %{
          forwarding_email_address: "another@chat.papercups.io",
          account: another_account
        })

      # Using the original session, try to delete the new account's forwarding_address
      conn =
        get(
          authed_conn,
          Routes.forwarding_address_path(authed_conn, :show, forwarding_address.id)
        )

      assert json_response(conn, 404)
    end
  end

  describe "create forwarding_address" do
    test "renders forwarding_address when data is valid", %{
      authed_conn: authed_conn,
      account: account
    } do
      resp =
        post(authed_conn, Routes.forwarding_address_path(authed_conn, :create),
          forwarding_address:
            params_for(:forwarding_address,
              account: account,
              forwarding_email_address: "test@chat.papercups.io"
            )
        )

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.forwarding_address_path(authed_conn, :show, id))
      account_id = account.id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "object" => "forwarding_address",
               "forwarding_email_address" => "test@chat.papercups.io"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.forwarding_address_path(authed_conn, :create),
          forwarding_address: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update forwarding_address" do
    test "renders forwarding_address when data is valid", %{
      authed_conn: authed_conn,
      forwarding_address: %ForwardingAddress{id: id} = forwarding_address
    } do
      conn =
        put(authed_conn, Routes.forwarding_address_path(authed_conn, :update, forwarding_address),
          forwarding_address: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.forwarding_address_path(authed_conn, :show, id))
      account_id = forwarding_address.account_id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "object" => "forwarding_address",
               "forwarding_email_address" => "updated@forwarding.com",
               "source_email_address" => "updated@source.com",
               "description" => "some updated description",
               "state" => "some updated state"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      forwarding_address: forwarding_address
    } do
      conn =
        put(authed_conn, Routes.forwarding_address_path(authed_conn, :update, forwarding_address),
          forwarding_address: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders 404 when editing another account's forwarding_address",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a forwarding_address
      another_account = insert(:account)

      forwarding_address =
        insert(:forwarding_address, %{
          forwarding_email_address: "forwarding@another.co",
          account: another_account
        })

      # Using the original session, try to update the new account's forwarding_address
      conn =
        put(
          authed_conn,
          Routes.forwarding_address_path(authed_conn, :update, forwarding_address),
          forwarding_address: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete forwarding_address" do
    test "deletes chosen forwarding_address", %{
      authed_conn: authed_conn,
      forwarding_address: forwarding_address
    } do
      conn =
        delete(
          authed_conn,
          Routes.forwarding_address_path(authed_conn, :delete, forwarding_address)
        )

      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.forwarding_address_path(authed_conn, :show, forwarding_address))
      end)
    end

    test "renders 404 when deleting another account's forwarding_address",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a forwarding_address
      another_account = insert(:account)

      forwarding_address =
        insert(:forwarding_address, %{
          forwarding_email_address: "another@forwarding.co",
          account: another_account
        })

      # Using the original session, try to delete the new account's forwarding_address
      conn =
        delete(
          authed_conn,
          Routes.forwarding_address_path(authed_conn, :delete, forwarding_address)
        )

      assert json_response(conn, 404)
    end
  end
end
