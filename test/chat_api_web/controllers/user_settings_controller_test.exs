defmodule ChatApiWeb.UserSettingsControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.{Accounts, Users, Repo}
  alias ChatApi.Users.User

  @create_attrs %{
    email_alert_on_new_message: true
  }
  @update_attrs %{
    email_alert_on_new_message: false
  }

  @password "supersecret123"

  def user_settings_fixture(attrs \\ %{}) do
    {:ok, user_settings} =
      attrs
      |> Enum.into(attrs)
      |> Users.create_user_settings()

    user_settings
  end

  setup %{conn: conn} do
    {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

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

    {:ok, conn: conn, authed_conn: authed_conn, user: user}
  end

  describe "create_or_update user_settings" do
    test "creates or updates a user's settings", %{
      authed_conn: authed_conn
    } do
      resp =
        put(authed_conn, Routes.user_settings_path(authed_conn, :create_or_update),
          user_settings: @create_attrs
        )

      assert %{"email_alert_on_new_message" => email_alert_on_new_message} =
               json_response(resp, 200)["data"]

      assert email_alert_on_new_message == @create_attrs.email_alert_on_new_message

      resp =
        put(authed_conn, Routes.user_settings_path(authed_conn, :create_or_update),
          user_settings: @update_attrs
        )

      assert %{"email_alert_on_new_message" => email_alert_on_new_message} =
               json_response(resp, 200)["data"]

      assert email_alert_on_new_message == @update_attrs.email_alert_on_new_message
    end
  end

  describe "show user_settings" do
    test "retrieves the user's settings", %{authed_conn: authed_conn, user: user} do
      attrs = Map.merge(@create_attrs, %{user_id: user.id})
      user_settings = user_settings_fixture(attrs)
      resp = get(authed_conn, Routes.user_settings_path(authed_conn, :show, %{}))

      assert %{"email_alert_on_new_message" => email_alert_on_new_message} =
               json_response(resp, 200)["data"]

      assert email_alert_on_new_message == user_settings.email_alert_on_new_message
    end
  end
end
