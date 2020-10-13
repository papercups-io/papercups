defmodule ChatApiWeb.TagControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.Tags.Tag

  @create_attrs %{
    name: "some name"
  }
  @update_attrs %{
    name: "some updated name"
  }
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    account = account_fixture()
    user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all tags", %{authed_conn: authed_conn} do
      resp = get(authed_conn, Routes.tag_path(authed_conn, :index))
      assert json_response(resp, 200)["data"] == []
    end
  end

  describe "create tag" do
    test "renders tag when data is valid", %{authed_conn: authed_conn} do
      resp = post(authed_conn, Routes.tag_path(authed_conn, :create), tag: @create_attrs)
      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.tag_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "name" => "some name"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      resp = post(authed_conn, Routes.tag_path(authed_conn, :create), tag: @invalid_attrs)
      assert json_response(resp, 422)["errors"] != %{}
    end
  end

  describe "update tag" do
    setup [:create_tag]

    test "renders tag when data is valid", %{authed_conn: authed_conn, tag: %Tag{id: id} = tag} do
      conn = put(authed_conn, Routes.tag_path(authed_conn, :update, tag), tag: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.tag_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn, tag: tag} do
      conn = put(authed_conn, Routes.tag_path(authed_conn, :update, tag), tag: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete tag" do
    setup [:create_tag]

    test "deletes chosen tag", %{authed_conn: authed_conn, tag: tag} do
      conn = delete(authed_conn, Routes.tag_path(authed_conn, :delete, tag))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.tag_path(authed_conn, :show, tag))
      end
    end
  end

  defp create_tag(%{account: account}) do
    tag = tag_fixture(account)

    %{tag: tag}
  end
end
