defmodule ChatApiWeb.ConversationControllerTest do
  use ChatApiWeb.ConnCase, async: true

  alias ChatApi.Conversations.Conversation

  @create_attrs %{
    status: "open"
  }
  @update_attrs %{
    status: "closed"
  }
  @invalid_attrs %{status: nil}

  setup %{conn: conn} do
    account = account_fixture()
    user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}
    conversation = conversation_fixture(account, customer_fixture(account))
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account, conversation: conversation}
  end

  describe "index" do
    test "lists all conversations", %{authed_conn: authed_conn, conversation: conversation} do
      conn = get(authed_conn, Routes.conversation_path(authed_conn, :index))
      ids = json_response(conn, 200)["data"] |> Enum.map(& &1["id"])
      assert ids == [conversation.id]
    end
  end

  describe "create conversation" do
    test "renders conversation when data is valid", %{authed_conn: authed_conn, account: account} do
      attrs = Map.put(@create_attrs, :account_id, account.id)

      conn =
        post(authed_conn, Routes.conversation_path(authed_conn, :create), conversation: attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(authed_conn, Routes.conversation_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "status" => "open"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.conversation_path(authed_conn, :create),
          conversation: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update conversation" do
    test "renders conversation when data is valid", %{
      authed_conn: authed_conn,
      conversation: %Conversation{id: id} = conversation
    } do
      conn =
        put(authed_conn, Routes.conversation_path(authed_conn, :update, conversation),
          conversation: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.conversation_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "status" => "closed"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      conversation: conversation
    } do
      conn =
        put(authed_conn, Routes.conversation_path(authed_conn, :update, conversation),
          conversation: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete conversation" do
    test "deletes chosen conversation", %{authed_conn: authed_conn, conversation: conversation} do
      conn = delete(authed_conn, Routes.conversation_path(authed_conn, :delete, conversation))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.conversation_path(authed_conn, :show, conversation))
      end)
    end
  end

  # TODO: add some more tests!
  describe "adding/removing tags" do
    test "adds a tag", %{authed_conn: authed_conn, conversation: conversation, account: account} do
      tag = tag_fixture(account, %{name: "Test Tag"})

      resp =
        post(authed_conn, Routes.conversation_path(authed_conn, :add_tag, conversation),
          tag_id: tag.id
        )

      assert json_response(resp, 200)["data"]["ok"]
      resp = get(authed_conn, Routes.conversation_path(authed_conn, :show, conversation.id))

      assert %{
               "tags" => tags
             } = json_response(resp, 200)["data"]

      assert [%{"name" => "Test Tag"}] = tags
    end

    test "removes a tag", %{
      authed_conn: authed_conn,
      conversation: conversation,
      account: account
    } do
      tag = tag_fixture(account, %{name: "Test Tag"})

      resp =
        post(authed_conn, Routes.conversation_path(authed_conn, :add_tag, conversation),
          tag_id: tag.id
        )

      assert json_response(resp, 200)["data"]["ok"]

      resp =
        delete(authed_conn, Routes.conversation_path(authed_conn, :remove_tag, conversation, tag))

      assert json_response(resp, 200)["data"]["ok"]
    end
  end
end
