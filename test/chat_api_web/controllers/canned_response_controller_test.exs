defmodule ChatApiWeb.CannedResponseControllerTest do
  use ChatApiWeb.ConnCase
  import ChatApi.Factory

  @update_attrs %{
    content: "some updated content",
    name: "some updated name"
  }
  @invalid_attrs %{content: nil, name: nil}

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all canned_responses",
         %{authed_conn: authed_conn} do
      authed_conn = get(authed_conn, Routes.canned_response_path(authed_conn, :index))
      assert json_response(authed_conn, 200)["data"] == []
    end
  end

  describe "create canned_response" do
    test "renders canned_response when data is valid", %{
      authed_conn: authed_conn,
      account: account
    } do
      conn =
        post(authed_conn, Routes.canned_response_path(authed_conn, :create),
          canned_response: %{
            content: "some content",
            name: "some name",
            account_id: account.id
          }
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(authed_conn, Routes.canned_response_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "content" => "some content",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.canned_response_path(authed_conn, :create),
          canned_response: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders errors when submitting canned response with duplicate name for the same account",
         %{authed_conn: authed_conn, account: account} do
      first_canned_response =
        insert(:canned_response, %{
          name: "First response name",
          content: "First response content",
          account: account
        })

      conn =
        post(authed_conn, Routes.canned_response_path(authed_conn, :create),
          canned_response: %{
            name: first_canned_response.name,
            content: "New content",
            account_id: account.id
          }
        )

      assert json_response(conn, 422)["error"]["errors"]
             |> Map.has_key?("unique_canned_response_per_account")
    end
  end

  describe "update canned_response" do
    test "renders canned_response when data is valid", %{
      authed_conn: authed_conn,
      account: account
    } do
      canned_response =
        insert(:canned_response, %{name: "Name", content: "Content", account: account})

      id = canned_response.id

      conn =
        put(authed_conn, Routes.canned_response_path(authed_conn, :update, canned_response),
          canned_response: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.canned_response_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "content" => "some updated content",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      account: account
    } do
      canned_response =
        insert(:canned_response, %{name: "Name", content: "Content", account: account})

      conn =
        put(authed_conn, Routes.canned_response_path(authed_conn, :update, canned_response),
          canned_response: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders errors when editing canned response to have duplicated name for the same account",
         %{authed_conn: authed_conn, account: account} do
      first_canned_response =
        insert(:canned_response, %{
          name: "First response name",
          content: "First response content",
          account: account
        })

      second_canned_response =
        insert(:canned_response, %{
          name: "Second response name",
          content: "Second response content",
          account: account
        })

      conn =
        put(
          authed_conn,
          Routes.canned_response_path(authed_conn, :update, second_canned_response),
          canned_response: %{
            name: first_canned_response.name,
            content: "New content",
            account_id: account.id
          }
        )

      assert json_response(conn, 422)["error"]["errors"]
             |> Map.has_key?("unique_canned_response_per_account")
    end
  end

  describe "delete canned_response" do
    test "deletes chosen canned_response", %{
      authed_conn: authed_conn
    } do
      canned_response = insert(:canned_response, %{name: "Name", content: "Content"})

      conn =
        delete(authed_conn, Routes.canned_response_path(authed_conn, :delete, canned_response))

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.canned_response_path(authed_conn, :show, canned_response))
      end
    end
  end
end
