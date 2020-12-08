defmodule ChatApiWeb.MessageControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.Messages.Message

  @update_attrs %{
    body: "some updated body"
  }
  @invalid_attrs %{body: nil}

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    conversation = insert(:conversation, account: account)
    message = insert(:message, account: account, conversation: conversation)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok,
     conn: conn,
     authed_conn: authed_conn,
     account: account,
     message: message,
     conversation: conversation}
  end

  describe "index" do
    test "lists all messages", %{authed_conn: authed_conn, message: message} do
      conn = get(authed_conn, Routes.message_path(authed_conn, :index))

      ids = json_response(conn, 200)["data"] |> Enum.map(& &1["id"])
      assert ids == [message.id]
    end

    test "returns unauthorized when auth is invalid", %{conn: conn} do
      conn = get(conn, Routes.message_path(conn, :index))

      assert json_response(conn, 401)["errors"] != %{}
    end
  end

  describe "create message" do
    test "renders message when data is valid",
         %{
           authed_conn: authed_conn,
           account: account,
           conversation: conversation
         } do
      message = %{
        body: "some body",
        account_id: account.id,
        conversation_id: conversation.id
      }

      conn = post(authed_conn, Routes.message_path(authed_conn, :create), message: message)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(authed_conn, Routes.message_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "object" => "message",
               "body" => "some body"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn = post(authed_conn, Routes.message_path(authed_conn, :create), message: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update message" do
    test "renders message when data is valid",
         %{authed_conn: authed_conn, message: %Message{id: id} = message} do
      conn =
        put(authed_conn, Routes.message_path(authed_conn, :update, message),
          message: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.message_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "body" => "some updated body"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid",
         %{authed_conn: authed_conn, message: message} do
      conn =
        put(authed_conn, Routes.message_path(authed_conn, :update, message),
          message: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete message" do
    test "deletes chosen message",
         %{authed_conn: authed_conn, message: message} do
      conn = delete(authed_conn, Routes.message_path(authed_conn, :delete, message))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.message_path(authed_conn, :show, message))
      end)
    end
  end
end
