defmodule ChatApiWeb.ConversationControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.Conversations
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Accounts

  @create_attrs %{
    status: "open"
  }
  @update_attrs %{
    status: "closed"
  }
  @invalid_attrs %{status: nil}

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    account
  end

  def fixture(:conversation) do
    account = fixture(:account)

    {:ok, conversation} =
      @create_attrs
      |> Enum.into(%{account_id: account.id})
      |> Conversations.create_conversation()

    conversation
  end

  setup %{conn: conn} do
    user = %ChatApi.Users.User{email: "test@example.com"}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])
    account = fixture(:account)

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all conversations", %{authed_conn: authed_conn} do
      conn = get(authed_conn, Routes.conversation_path(authed_conn, :index))
      assert json_response(conn, 200)["data"] == []
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
    setup [:create_conversation]

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
    setup [:create_conversation]

    test "deletes chosen conversation", %{authed_conn: authed_conn, conversation: conversation} do
      conn = delete(authed_conn, Routes.conversation_path(authed_conn, :delete, conversation))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.conversation_path(authed_conn, :show, conversation))
      end)
    end
  end

  defp create_conversation(_) do
    conversation = fixture(:conversation)
    %{conversation: conversation}
  end
end
