defmodule ChatApiWeb.SlackControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ExUnit.CaptureLog

  alias ChatApi.Messages

  setup %{conn: conn} do
    account = account_fixture()
    user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}
    auth = slack_authorization_fixture(account)
    customer = customer_fixture(account)
    conversation = conversation_fixture(account, customer)
    thread = slack_conversation_thread_fixture(conversation)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, thread: thread, auth: auth}
  end

  describe "authorization" do
    test "gets the authorization details if they exist", %{authed_conn: authed_conn, auth: auth} do
      resp = get(authed_conn, Routes.slack_path(authed_conn, :authorization), %{})

      assert %{
               "channel" => channel,
               "team_name" => team_name
             } = json_response(resp, 200)["data"]

      assert channel == auth.channel
      assert team_name == auth.team_name
    end

    test "returns nil if the authorization does not exist", %{conn: conn} do
      new_account = account_fixture()
      user = user_fixture(new_account)
      authed_conn = Pow.Plug.assign_current_user(conn, user, [])
      resp = get(authed_conn, Routes.slack_path(authed_conn, :authorization), %{})

      assert %{"data" => nil} = json_response(resp, 200)
    end
  end

  describe "webhook" do
    test "sends an event to the webhook", %{conn: conn, thread: thread, auth: auth} do
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
  end
end
