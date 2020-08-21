defmodule ChatApiWeb.MessageControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.{Accounts, Conversations, Messages, Repo}
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User

  @update_attrs %{
    body: "some updated body"
  }
  @invalid_attrs %{body: nil}

  @password "supersecret123"

  def valid_create_attrs(account_id) do
    {:ok, conversation} =
      Conversations.create_conversation(%{status: "open", account_id: account_id})

    %{
      body: "some body",
      account_id: account_id,
      conversation_id: conversation.id
    }
  end

  def fixture(:message) do
    {:ok, message} =
      fixture(:account)
      |> Map.get(:id)
      |> valid_create_attrs()
      |> Messages.create_message()

    message
  end

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    account
  end

  setup %{conn: conn} do
    account = fixture(:account)

    user =
      %User{}
      |> User.changeset(%{
        email: "test@example.com",
        password: @password,
        password_confirmation: @password,
        account_id: account.id
      })
      |> Repo.insert!()

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all messages", %{authed_conn: authed_conn} do
      conn = get(authed_conn, Routes.message_path(authed_conn, :index))

      assert json_response(conn, 200)["data"] == []
    end

    test "returns unauthorized when auth is invalid", %{conn: conn} do
      conn = get(conn, Routes.message_path(conn, :index))

      assert json_response(conn, 401)["errors"] != %{}
    end
  end

  describe "create message" do
    test "renders message when data is valid", %{authed_conn: authed_conn, account: account} do
      message = valid_create_attrs(account.id)

      conn = post(authed_conn, Routes.message_path(authed_conn, :create), message: message)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(authed_conn, Routes.message_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "body" => "some body"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn = post(authed_conn, Routes.message_path(authed_conn, :create), message: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update message" do
    setup [:create_message]

    test "renders message when data is valid", %{
      authed_conn: authed_conn,
      message: %Message{id: id} = message
    } do
      conn =
        put(authed_conn, Routes.message_path(authed_conn, :update, message),
          message: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.message_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "body" => "some updated body"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn, message: message} do
      conn =
        put(authed_conn, Routes.message_path(authed_conn, :update, message),
          message: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete message" do
    setup [:create_message]

    test "deletes chosen message", %{authed_conn: authed_conn, message: message} do
      conn = delete(authed_conn, Routes.message_path(authed_conn, :delete, message))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.message_path(authed_conn, :show, message))
      end)
    end
  end

  defp create_message(_) do
    message = fixture(:message)
    %{message: message}
  end
end
