defmodule ChatApiWeb.CannedResponseControllerTest do
  use ChatApiWeb.ConnCase

  import ChatApi.Factory

  alias ChatApi.CannedResponses
  alias ChatApi.CannedResponses.CannedResponse

  @create_attrs %{name: "some name", content: "some content"}
  @update_attrs %{
    content: "some updated content",
    name: "some updated name"
  }
  @invalid_attrs %{content: nil, name: nil}

  def fixture(:canned_response) do
    {:ok, canned_response} = CannedResponses.create_canned_response(@create_attrs)
    canned_response
  end

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all canned_responses", %{authed_conn: authed_conn} do
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

  describe "show canned_response" do
    test "renders 404 when asking for another user's canned_response", %{
      conn: conn,
      account: account
    } do
      # Make a canned_response with a first user
      canned_response =
        insert(:canned_response, %{
          name: "First response name",
          content: "First response content",
          account: account
        })

      # Make a new account and session
      new_account = insert(:account)
      new_user = insert(:user, account: new_account)
      new_conn = put_req_header(conn, "accept", "application/json")
      new_authed_conn = Pow.Plug.assign_current_user(new_conn, new_user, [])

      # Using the new account/session, try to get the other user's canned_response
      conn =
        get(
          new_authed_conn,
          Routes.canned_response_path(new_authed_conn, :show, canned_response.id)
        )

      assert json_response(conn, 404)
    end
  end

  describe "create canned_response" do
    test "renders canned_response when data is valid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.canned_response_path(authed_conn, :create),
          canned_response: params_with_assocs(:canned_response, @create_attrs)
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

    test "renders errors when there are two same name in a single account", %{
      authed_conn: authed_conn,
      account: account
    } do
      conn =
        post(authed_conn, Routes.canned_response_path(authed_conn, :create),
          canned_response:
            params_for(:canned_response, %{
              account: account,
              name: "some name",
              content: "some content"
            })
        )

      assert %{"id" => _id} = json_response(conn, 201)["data"]

      conn =
        post(authed_conn, Routes.canned_response_path(authed_conn, :create),
          canned_response:
            params_for(:canned_response, %{
              account: account,
              name: "some name",
              content: "new content"
            })
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update canned_response" do
    setup [:create_canned_response]

    test "renders canned_response when data is valid", %{
      authed_conn: authed_conn,
      canned_response: %CannedResponse{id: id} = canned_response
    } do
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
      canned_response: canned_response
    } do
      conn =
        put(authed_conn, Routes.canned_response_path(authed_conn, :update, canned_response),
          canned_response: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders 404 when editing another account's canned response",
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

      assert json_response(conn, 404)
    end
  end

  describe "delete canned_response" do
    setup [:create_canned_response]

    test "deletes chosen canned_response", %{
      authed_conn: authed_conn,
      canned_response: canned_response
    } do
      conn =
        delete(authed_conn, Routes.canned_response_path(authed_conn, :delete, canned_response))

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.canned_response_path(authed_conn, :show, canned_response))
      end
    end

    test "renders 404 when deleting another account's canned response",
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
        delete(
          new_authed_conn,
          Routes.canned_response_path(new_authed_conn, :delete, canned_response)
        )

      assert json_response(conn, 404)
    end
  end

  defp create_canned_response(%{account: account}) do
    canned_response = insert(:canned_response, account: account)
    %{canned_response: canned_response}
  end
end
