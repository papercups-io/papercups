defmodule ChatApiWeb.TagControllerTest do
  use ChatApiWeb.ConnCase

  import ChatApi.Factory
  alias ChatApi.Tags.Tag

  @create_attrs params_for(:tag, name: "some name")
  @update_attrs %{
    name: "some updated name"
  }
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)

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
               "id" => _id,
               "object" => "tag",
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
               "id" => _id,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn, tag: tag} do
      conn = put(authed_conn, Routes.tag_path(authed_conn, :update, tag), tag: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    # test "renders errors when editing another account's tag",
    #      %{conn: conn, account: account, tag: %Tag{id: id} = tag} do
    #   new_account = insert(:account)
    #   new_user = insert(:user, account: new_account)
    #   new_conn = put_req_header(conn, "accept", "application/json")
    #   new_authed_conn = Pow.Plug.assign_current_user(new_conn, new_user, [])

    #   conn =
    #     put(
    #       new_authed_conn,
    #       Routes.tag_path(new_authed_conn, :update, tag),
    #       tag: @update_attrs
    #     )

    #   assert json_response(conn, 401)["error"]["errors"]
    # end
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
    tag = insert(:tag, account: account)

    %{tag: tag}
  end
end
