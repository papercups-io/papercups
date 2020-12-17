defmodule ChatApiWeb.SlackControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  import ExUnit.CaptureLog
  import Mock

  alias ChatApi.Messages

  @email "customer@test.com"

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    customer = insert(:customer, account: account, email: @email)
    conversation = insert(:conversation, account: account, customer: customer)
    auth = insert(:slack_authorization, account: account)
    thread = insert(:slack_conversation_thread, conversation: conversation, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, thread: thread, auth: auth, account: account}
  end

  describe "authorization" do
    test "gets the authorization details if they exist",
         %{authed_conn: authed_conn, auth: auth} do
      resp = get(authed_conn, Routes.slack_path(authed_conn, :authorization), %{})

      assert %{
               "channel" => channel,
               "team_name" => team_name
             } = json_response(resp, 200)["data"]

      assert channel == auth.channel
      assert team_name == auth.team_name
    end

    test "returns nil if the authorization does not exist", %{conn: conn} do
      user = insert(:user)

      authed_conn = Pow.Plug.assign_current_user(conn, user, [])
      resp = get(authed_conn, Routes.slack_path(authed_conn, :authorization), %{})

      assert %{"data" => nil} = json_response(resp, 200)
    end
  end

  describe "webhook" do
    test "sends a new thread message event to the webhook", %{
      conn: conn,
      thread: thread,
      auth: auth
    } do
      account_id = thread.account_id

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => thread.slack_channel,
        "user" => auth.authed_user_id
      }

      # TODO: figure out a better way to handle Slack warnings in test mode
      assert capture_log(fn ->
               post(conn, Routes.slack_path(conn, :webhook), %{
                 "event" => event_params
               })
             end)

      assert [%{body: body}] = Messages.list_messages(account_id)
      assert body == event_params["text"]
    end

    test "sends a new message event to the webhook", %{conn: conn, account: account} do
      authorization = insert(:slack_authorization, account: account, type: "support")

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "channel" => authorization.channel_id,
        "team" => authorization.team_id,
        "user" => authorization.authed_user_id,
        "ts" => "1234.56789"
      }

      slack_user = %{
        "real_name" => "Test User",
        "tz" => "America/New_York",
        "profile" => %{"email" => @email}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end,
        send_message: fn _, _ -> {:ok, nil} end do
        # TODO: figure out a better way to handle Slack warnings in test mode
        assert capture_log(fn ->
                 post(conn, Routes.slack_path(conn, :webhook), %{
                   "event" => event_params
                 })
               end)

        assert [%{body: body}] = Messages.list_messages(account.id)
        assert body == event_params["text"]
      end
    end
  end
end
