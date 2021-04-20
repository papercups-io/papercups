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

  describe "show tag" do
    setup [:create_tag]

    test "shows tag by id", %{
      authed_conn: authed_conn,
      tag: tag
    } do
      conn =
        get(
          authed_conn,
          Routes.tag_path(authed_conn, :show, tag.id)
        )

      assert json_response(conn, 200)["data"]
    end

    test "renders 404 when asking for another user's tag", %{
      authed_conn: authed_conn
    } do
      # Create a new account and give it a tag
      another_account = insert(:account)

      another_tag =
        insert(:tag, %{
          name: "Another tag name",
          account: another_account
        })

      # Using the original session, try to delete the new account's tag
      conn =
        get(
          authed_conn,
          Routes.tag_path(authed_conn, :show, another_tag.id)
        )

      assert json_response(conn, 404)
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

    test "renders 404 when updating another account's tag",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a tag
      another_account = insert(:account)

      another_tag =
        insert(:tag, %{
          name: "Another tag name",
          account: another_account
        })

      # Using the original session, try to update the new account's tag
      conn =
        put(
          authed_conn,
          Routes.tag_path(authed_conn, :update, another_tag),
          tag: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete tag" do
    setup [:create_tag]

    test "deletes chosen tag", %{authed_conn: authed_conn, tag: tag} do
      conn = delete(authed_conn, Routes.tag_path(authed_conn, :delete, tag))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.tag_path(authed_conn, :show, tag))
      end)
    end

    test "renders 404 when deleting another account's tag",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a tag
      another_account = insert(:account)

      tag =
        insert(:tag, %{
          name: "Another tag name",
          account: another_account
        })

      # Using the original session, try to delete the new account's tag
      conn = delete(authed_conn, Routes.tag_path(authed_conn, :delete, tag))

      assert json_response(conn, 404)
    end
  end

  defp create_tag(%{account: account}) do
    tag = insert(:tag, account: account)

    %{tag: tag}
  end
end
