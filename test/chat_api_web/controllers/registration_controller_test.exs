defmodule ChatApiWeb.RegistrationControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.{Accounts, Repo, UserInvitations}

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
        "company_name" => "Invalid Inc"
      }
    }

    @missing_company_name %{
      "user" => %{
        "email" => "invalid",
        "password" => @password,
        "password_confirmation" => @password,
        "company_name" => ""
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

      # No accounts should have been created
      assert [] = Accounts.list_accounts()
    end

    test "with missing company name", %{conn: conn} do
      conn = post(conn, Routes.registration_path(conn, :create, @missing_company_name))

      assert json = json_response(conn, 500)
      assert json["error"]["message"] == "Couldn't create user"
      assert json["error"]["status"] == 500
      assert json["error"]["errors"]["company_name"] == ["can't be blank"]

      # No accounts should have been created
      assert [] = Accounts.list_accounts()
    end
  end

  describe("registering with invitation token") do
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

      existing_user = %ChatApi.Users.User{
        email: "test@example.com",
        role: "admin",
        account_id: account.id
      }

      # conn = put_req_header(conn, "accept", "application/json")
      authed_conn = Pow.Plug.assign_current_user(conn, existing_user, [])

      {:ok, authed_conn: authed_conn, account: account, user: existing_user}
    end

    test "create with existing user", %{conn: conn, authed_conn: authed_conn, account: account} do
      existing_conn =
        post(authed_conn, Routes.user_invitation_path(authed_conn, :create),
          user_invitation: %{account_id: account.id}
        )

      invite_token = json_response(existing_conn, 201)["data"]["id"]

      random_number = :rand.uniform(1_000_000_000) |> Integer.to_string()
      registration_email = random_number <> "anotheremail@example.com"

      params = %{
        "user" => %{
          "invite_token" => invite_token,
          "email" => registration_email,
          "password" => @password,
          "password_confirmation" => @password
        }
      }

      post(conn, Routes.registration_path(conn, :create, params))
      account = Accounts.get_account!(account.id) |> Repo.preload([:users])

      assert(Enum.any?(account.users, fn u -> u.email == registration_email end))
    end

    test "error for non-existing invite token", %{conn: conn} do
      random_number = :rand.uniform(1_000_000_000) |> Integer.to_string()
      registration_email = random_number <> "anotheremail@example.com"

      params = %{
        "user" => %{
          "invite_token" => "093ada1d-02c2-4e08-bdd1-d0d6e567db2e",
          "email" => registration_email,
          "password" => @password,
          "password_confirmation" => @password
        }
      }

      existing_conn = post(conn, Routes.registration_path(conn, :create, params))
      assert json = json_response(existing_conn, 403)
      assert json["error"]["message"] == "Invalid invitation token"
      assert json["error"]["status"] == 403
    end

    test "error for expired invite token", %{conn: conn, account: account} do
      {_, user_invitation} = UserInvitations.create_user_invitation(%{account_id: account.id})
      UserInvitations.expire_user_invitation(user_invitation)

      random_number = :rand.uniform(1_000_000_000) |> Integer.to_string()
      registration_email = random_number <> "anotheremail@example.com"

      params = %{
        "user" => %{
          "invite_token" => user_invitation.id,
          "email" => registration_email,
          "password" => @password,
          "password_confirmation" => @password
        }
      }

      existing_conn = post(conn, Routes.registration_path(conn, :create, params))
      assert json = json_response(existing_conn, 403)
      assert json["error"]["message"] == "Invitation token has expired"
      assert json["error"]["status"] == 403
    end
  end
end
