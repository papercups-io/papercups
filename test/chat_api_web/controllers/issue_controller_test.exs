defmodule ChatApiWeb.IssueControllerTest do
  use ChatApiWeb.ConnCase

  import ChatApi.Factory
  alias ChatApi.Issues.Issue

  @create_attrs params_for(:issue, title: "some title")
  @update_attrs %{
    title: "some updated title"
  }
  @invalid_attrs %{title: nil}

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all issues", %{authed_conn: authed_conn} do
      resp = get(authed_conn, Routes.issue_path(authed_conn, :index))
      assert json_response(resp, 200)["data"] == []
    end
  end

  describe "create issue" do
    test "renders issue when data is valid", %{authed_conn: authed_conn} do
      resp = post(authed_conn, Routes.issue_path(authed_conn, :create), issue: @create_attrs)
      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.issue_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "object" => "issue",
               "title" => "some title"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      resp = post(authed_conn, Routes.issue_path(authed_conn, :create), issue: @invalid_attrs)
      assert json_response(resp, 422)["errors"] != %{}
    end
  end

  describe "show issue" do
    setup [:create_issue]

    test "shows issue by id", %{
      authed_conn: authed_conn,
      issue: issue
    } do
      conn =
        get(
          authed_conn,
          Routes.issue_path(authed_conn, :show, issue.id)
        )

      assert json_response(conn, 200)["data"]
    end

    test "renders 404 when asking for another user's issue", %{
      authed_conn: authed_conn
    } do
      # Create a new account and give it a issue
      another_account = insert(:account)

      another_issue =
        insert(:issue, %{
          title: "Another issue title",
          account: another_account
        })

      # Using the original session, try to delete the new account's issue
      conn =
        get(
          authed_conn,
          Routes.issue_path(authed_conn, :show, another_issue.id)
        )

      assert json_response(conn, 404)
    end
  end

  describe "update issue" do
    setup [:create_issue]

    test "renders issue when data is valid", %{
      authed_conn: authed_conn,
      issue: %Issue{id: id} = issue
    } do
      conn =
        put(authed_conn, Routes.issue_path(authed_conn, :update, issue), issue: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.issue_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn, issue: issue} do
      conn =
        put(authed_conn, Routes.issue_path(authed_conn, :update, issue), issue: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders 404 when updating another account's issue",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a issue
      another_account = insert(:account)

      another_issue =
        insert(:issue, %{
          title: "Another issue title",
          account: another_account
        })

      # Using the original session, try to update the new account's issue
      conn =
        put(
          authed_conn,
          Routes.issue_path(authed_conn, :update, another_issue),
          issue: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete issue" do
    setup [:create_issue]

    test "deletes chosen issue", %{authed_conn: authed_conn, issue: issue} do
      conn = delete(authed_conn, Routes.issue_path(authed_conn, :delete, issue))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.issue_path(authed_conn, :show, issue))
      end)
    end

    test "renders 404 when deleting another account's issue",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a issue
      another_account = insert(:account)

      issue =
        insert(:issue, %{
          title: "Another issue title",
          account: another_account
        })

      # Using the original session, try to delete the new account's issue
      conn = delete(authed_conn, Routes.issue_path(authed_conn, :delete, issue))

      assert json_response(conn, 404)
    end
  end

  defp create_issue(%{account: account}) do
    issue = insert(:issue, account: account)

    %{issue: issue}
  end
end
