defmodule ChatApiWeb.CannedResponseControllerTest do
  use ChatApiWeb.ConnCase
  import ChatApi.Factory

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
      conn = get(authed_conn, Routes.canned_response_path(authed_conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "returns unauthorized when auth is invalid", %{conn: conn} do
      conn = get(conn, Routes.canned_response_path(conn, :index))

      assert json_response(conn, 401)["errors"] != %{}
    end

    test "lists canned_responses only for this account",
         %{authed_conn: authed_conn, account: account} do
      insert(:canned_response, %{
        name: "First response name",
        content: "First response content",
        account: account
      })

      conn = get(authed_conn, Routes.canned_response_path(authed_conn, :index))

      assert json_response(conn, 200)["data"] |> length() == 1

      # Nw, make another account and canned response, and make sure we can't see that one in our query

      another_account = insert(:account)

      insert(:canned_response, %{
        name: "Another canned response name",
        content: "Another canned response content",
        account: another_account
      })

      conn = get(authed_conn, Routes.canned_response_path(authed_conn, :index))

      assert json_response(conn, 200)["data"] |> length() == 1
    end
  end

  describe "create canned_response" do
    test "renders canned_response when data is valid", %{
      authed_conn: authed_conn
    } do
      conn =
        post(authed_conn, Routes.canned_response_path(authed_conn, :create),
          content: "some content",
          name: "some name"
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
      conn = post(authed_conn, Routes.canned_response_path(authed_conn, :create), @invalid_attrs)

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
          name: first_canned_response.name,
          content: "New content"
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
          content: "some updated content",
          name: "some updated name"
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
          content: "some updated content",
          name: nil
        )

      assert json_response(conn, 422)["errors"] != %{}

      conn =
        put(authed_conn, Routes.canned_response_path(authed_conn, :update, canned_response),
          content: nil,
          name: "some updated name"
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
          name: first_canned_response.name,
          content: "New content"
        )

      assert json_response(conn, 422)["error"]["errors"]
             |> Map.has_key?("unique_canned_response_per_account")
    end

    test "renders errors when editing another account's canned response",
         %{conn: conn, account: account} do
      # Add a canned response for the first account
      canned_response =
        insert(:canned_response, %{
          name: "Canned response name",
          content: "Canned response content",
          account: account
        })

      new_account = insert(:account)
      new_user = insert(:user, account: new_account)
      new_conn = put_req_header(conn, "accept", "application/json")
      new_authed_conn = Pow.Plug.assign_current_user(new_conn, new_user, [])

      conn =
        put(
          new_authed_conn,
          Routes.canned_response_path(new_authed_conn, :update, canned_response),
          name: "New name",
          content: "New content"
        )

      assert json_response(conn, 403)["error"]["message"] == "Forbidden"
    end
  end

  describe "delete canned_response" do
    test "deletes chosen canned_response", %{
      authed_conn: authed_conn,
      account: account
    } do
      canned_response =
        insert(:canned_response, %{name: "Name", content: "Content", account: account})

      conn =
        delete(authed_conn, Routes.canned_response_path(authed_conn, :delete, canned_response))

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.canned_response_path(authed_conn, :show, canned_response))
      end
    end

    test "renders error when trying to delete another account's canned_response",
         %{conn: conn, authed_conn: authed_conn, account: account} do
      # Add a canned response for the first account
      canned_response =
        insert(:canned_response, %{
          name: "Canned response name",
          content: "Canned response content",
          account: account
        })

      new_account = insert(:account)
      new_user = insert(:user, account: new_account)
      new_conn = put_req_header(conn, "accept", "application/json")
      new_authed_conn = Pow.Plug.assign_current_user(new_conn, new_user, [])

      conn =
        delete(
          new_authed_conn,
          Routes.canned_response_path(new_authed_conn, :delete, canned_response)
        )

      assert json_response(conn, 403)["error"]["message"] == "Forbidden"

      # verify the canned response is still there for the right user

      conn = get(authed_conn, Routes.canned_response_path(authed_conn, :show, canned_response.id))

      assert canned_response = json_response(conn, 200)["data"]
    end
  end
end
