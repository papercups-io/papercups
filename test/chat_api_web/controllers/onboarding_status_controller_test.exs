defmodule ChatApiWeb.OnboardingStatusControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.{Accounts, Users, WidgetSettings}

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account, role: "admin")

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account, user: user}
  end

  describe "index" do
    test "has_configured_profile is true if display_name, full_name, or profile_photo_url has been set",
         %{authed_conn: authed_conn, user: user} do
      # false because all are nil
      Users.update_user_profile(user.id, %{
        display_name: nil,
        full_name: nil,
        profile_photo_url: nil
      })

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_configured_profile" => false} = json_response(response, 200)

      # true because display_name has been set
      Users.update_user_profile(user.id, %{
        display_name: "my display name",
        full_name: nil,
        profile_photo_url: nil
      })

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_configured_profile" => true} = json_response(response, 200)

      # true because full_name has been set
      Users.update_user_profile(user.id, %{
        display_name: nil,
        full_name: "my full name",
        profile_photo_url: nil
      })

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_configured_profile" => true} = json_response(response, 200)

      # true because profile_photo_url has been set
      Users.update_user_profile(user.id, %{
        display_name: nil,
        full_name: nil,
        profile_photo_url: "https://fake-images.com/cool-cat.jpg"
      })

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_configured_profile" => true} = json_response(response, 200)
    end

    test "has_configured_storytime is true if the account has browser sessions", %{
      authed_conn: authed_conn,
      account: account
    } do
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_configured_storytime" => false} = json_response(response, 200)

      insert(:browser_session, account: account)

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_configured_storytime" => true} = json_response(response, 200)
    end

    test "has_integrations is false if account doesn't have any integration authorizations", %{
      authed_conn: authed_conn
    } do
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => false} = json_response(response, 200)
    end

    test "has_integrations is true if account has a github authorization", %{
      authed_conn: authed_conn,
      account: account,
      user: user
    } do
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => false} = json_response(response, 200)

      insert(:github_authorization, account: account, user: user)

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => true} = json_response(response, 200)
    end

    test "has_integrations is true if account has a google authorization", %{
      authed_conn: authed_conn,
      account: account,
      user: user
    } do
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => false} = json_response(response, 200)

      insert(:google_authorization, account: account, user: user)

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => true} = json_response(response, 200)
    end

    test "has_integrations is true if account has a mattermost authorization", %{
      authed_conn: authed_conn,
      account: account,
      user: user
    } do
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => false} = json_response(response, 200)

      insert(:mattermost_authorization, account: account, user: user)

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => true} = json_response(response, 200)
    end

    test "has_integrations is true if account has a slack authorization", %{
      authed_conn: authed_conn,
      account: account
    } do
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => false} = json_response(response, 200)

      insert(:slack_authorization, account: account)

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => true} = json_response(response, 200)
    end

    test "has_integrations is true if account has a twilio authorization", %{
      authed_conn: authed_conn,
      account: account,
      user: user
    } do
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => false} = json_response(response, 200)

      insert(:twilio_authorization, account: account, user: user)

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_integrations" => true} = json_response(response, 200)
    end

    test "is_chat_widget_installed is true if the widget settings host exists and isn't papercups or localhost",
         %{authed_conn: authed_conn, account: account} do
      # false because host is nil
      widget_settings = WidgetSettings.get_settings_by_account(account.id)
      {:ok, widget_settings} = WidgetSettings.update_widget_setting(widget_settings, %{host: nil})
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"is_chat_widget_installed" => false} = json_response(response, 200)

      # false because host is empty string
      {:ok, widget_settings} = WidgetSettings.update_widget_setting(widget_settings, %{host: ""})
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"is_chat_widget_installed" => false} = json_response(response, 200)

      # false because host is papercups domain
      {:ok, widget_settings} =
        WidgetSettings.update_widget_setting(widget_settings, %{host: "app.papercups.io"})

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"is_chat_widget_installed" => false} = json_response(response, 200)

      # false because host is localhost
      {:ok, widget_settings} =
        WidgetSettings.update_widget_setting(widget_settings, %{host: "localhost:3000"})

      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"is_chat_widget_installed" => false} = json_response(response, 200)

      # true because host is set and isn't papercups or localhost
      WidgetSettings.update_widget_setting(widget_settings, %{host: "fake-domain.com"})
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"is_chat_widget_installed" => true} = json_response(response, 200)
    end

    test "has_invited_teammates is true if there are more than 1 active users for the account",
         %{authed_conn: authed_conn, account: account} do
      # false because only 1 active user
      active_users_count = Accounts.count_active_users(account.id)
      assert active_users_count == 1
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_invited_teammates" => false} = json_response(response, 200)

      # true because active user count > 1
      second_user = insert(:user, account: account)
      active_users_count = Accounts.count_active_users(account.id)
      assert active_users_count == 2
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_invited_teammates" => true} = json_response(response, 200)

      # false because second_user has been disabled so there's no longer more than 1 active users
      Users.disable_user(second_user)
      active_users_count = Accounts.count_active_users(account.id)
      assert active_users_count == 1
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_invited_teammates" => false} = json_response(response, 200)
    end

    test "has_upgraded_subscription is true if subscription is not starter", %{
      authed_conn: authed_conn,
      account: account
    } do
      assert account.subscription_plan == "starter"
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_upgraded_subscription" => false} = json_response(response, 200)

      Accounts.update_billing_info(account, %{subscription_plan: "lite"})
      response = get(authed_conn, Routes.onboarding_status_path(authed_conn, :index))
      assert %{"has_upgraded_subscription" => true} = json_response(response, 200)
    end
  end
end
