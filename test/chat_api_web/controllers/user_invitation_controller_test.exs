defmodule ChatApiWeb.UserInvitationControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.UserInvitations
  alias ChatApi.UserInvitations.UserInvitation
  alias ChatApi.Accounts

  @invalid_attrs %{account_id: nil, expires_at: nil}

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    account
  end

  def fixture(:user_invitation) do
    account = fixture(:account)
    {:ok, user_invitation} = UserInvitations.create_user_invitation(%{account_id: account.id})
    user_invitation
  end

  setup %{conn: conn} do
    account = fixture(:account)
    user = %ChatApi.Users.User{email: "test@example.com", role: "admin", account_id: account.id}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all user_invitations", %{authed_conn: authed_conn} do
      conn = get(authed_conn, Routes.user_invitation_path(authed_conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create user_invitation" do
    test "renders user_invitation when data is valid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.user_invitation_path(authed_conn, :create), user_invitation: %{})

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(authed_conn, Routes.user_invitation_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "account_id" => account_id
               #  "expires_at" => "2010-04-17",
               #  "token" => "some token"
             } = json_response(conn, 200)["data"]
    end
  end

  describe "update user_invitation" do
    setup [:create_user_invitation]

    test "renders user_invitation when data is valid", %{
      authed_conn: authed_conn,
      user_invitation: %UserInvitation{id: id} = user_invitation
    } do
      conn =
        put(authed_conn, Routes.user_invitation_path(authed_conn, :update, user_invitation),
          user_invitation: %{}
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.user_invitation_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "account_id" => account_id
               #  "expires_at" => "2011-05-18",
               #  "token" => "some updated token"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      user_invitation: user_invitation
    } do
      conn =
        put(authed_conn, Routes.user_invitation_path(authed_conn, :update, user_invitation),
          user_invitation: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user_invitation" do
    setup [:create_user_invitation]

    test "deletes chosen user_invitation", %{
      authed_conn: authed_conn,
      user_invitation: user_invitation
    } do
      conn =
        delete(authed_conn, Routes.user_invitation_path(authed_conn, :delete, user_invitation))

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.user_invitation_path(authed_conn, :show, user_invitation))
      end
    end
  end

  defp create_user_invitation(_) do
    user_invitation = fixture(:user_invitation)
    %{user_invitation: user_invitation}
  end
end
