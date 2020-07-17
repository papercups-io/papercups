defmodule ChatApiWeb.RegistrationControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.Accounts
  alias ChatApi.UserInvitations
  alias ChatApi.UserInvitations.UserInvitation

  @password "secret1234"

  describe "create/2" do
    @valid_params %{
      "user" => %{
        "company_name" => "Papercups",
        "email" => "test@example.com",
        "password" => @password,
        "password_confirmation" => @password
      }
    }

    @invalid_params %{
      "user" => %{
        "email" => "invalid",
        "password" => @password,
        "password_confirmation" => "",
        "company_name" => "test"
      }
    }

    test "with valid params", %{conn: conn} do
      conn = post(conn, Routes.registration_path(conn, :create, @valid_params))

      assert json = json_response(conn, 200)
      assert json["data"]["token"]
      assert json["data"]["renew_token"]
    end

    test "with invalid params", %{conn: conn} do
      conn = post(conn, Routes.registration_path(conn, :create, @invalid_params))

      assert json = json_response(conn, 500)
      assert json["error"]["message"] == "Couldn't create user"
      assert json["error"]["status"] == 500
      assert json["error"]["errors"]["password_confirmation"] == ["does not match confirmation"]
      assert json["error"]["errors"]["email"] == ["has invalid format"]
    end
  end

  describe("registering with invitation token") do
    # @valid_params %{
    #   "user" => %{
    #     "email" => "test@example.com",
    #     "password" => @password,
    #     "password_confirmation" => @password
    #   }
    # }

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
      user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}
      conn = put_req_header(conn, "accept", "application/json")
      authed_conn = Pow.Plug.assign_current_user(conn, user, [])
      # IO.inspect(user)

      {:ok, conn: conn, authed_conn: authed_conn, account: account}
    end

    test "create with existing user", %{authed_conn: authed_conn, account: account} do
      conn =
        post(authed_conn, Routes.user_invitation_path(authed_conn, :create),
          user_invitation: %{account_id: account.id}
        )

      invite_token = json_response(conn, 201)["data"]["invite_token"]
      params = %{
        "user" => %{
          "invite_token" => invite_token,
          "email" => "test@example.com",
          "password" => @password,
          "password_confirmation" => @password
        }
      }
      assert(invite_token != nil)
      conn = post(conn, Routes.registration_path(conn, :create, params))
      IO.inspect(json_response(conn, 201)["data"])
    end
  end
end
