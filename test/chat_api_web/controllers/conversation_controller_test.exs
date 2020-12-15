defmodule ChatApiWeb.ConversationControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.Conversations.Conversation

  @update_attrs %{
    status: "closed"
  }
  @invalid_attrs %{status: nil}

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account, email: "test@example.com")
    customer = insert(:customer, account: account)
    conversation = insert(:conversation, account: account, customer: customer)
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {
      :ok,
      conn: conn,
      authed_conn: authed_conn,
      account: account,
      customer: customer,
      conversation: conversation
    }
  end

  describe "index" do
    test "lists all conversations", %{authed_conn: authed_conn, conversation: conversation} do
      conn = get(authed_conn, Routes.conversation_path(authed_conn, :index))
      ids = json_response(conn, 200)["data"] |> Enum.map(& &1["id"])
      assert ids == [conversation.id]
    end
  end

  describe "create conversation" do
    test "renders conversation when data is valid", %{
      authed_conn: authed_conn,
      account: account,
      customer: customer
    } do
      attrs = params_for(:conversation, account: account, customer: customer)

      conn =
        post(authed_conn, Routes.conversation_path(authed_conn, :create), conversation: attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(authed_conn, Routes.conversation_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "object" => "conversation",
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
               "id" => _id,
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
    test "adds a tag",
         %{
           authed_conn: authed_conn,
           conversation: conversation,
           account: account
         } do
      tag = insert(:tag, account: account, name: "Test Tag")

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
      tag = insert(:tag, account: account, name: "Test Tag")

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
