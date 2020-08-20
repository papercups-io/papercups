defmodule ChatApiWeb.SlackControllerTest do
  use ChatApiWeb.ConnCase

  import ExUnit.CaptureLog

  alias ChatApi.{
    Accounts,
    Conversations,
    Messages,
    SlackAuthorizations,
    SlackConversationThreads
  }

  @slack_channel "#test"
  @slack_thread_ts "123.456"
  @slack_user_id "U123"

  @auth_params %{
    access_token: "xoxb-test-access-token",
    channel: @slack_channel,
    channel_id: @slack_channel,
    team_name: "Papercups"
  }

  @event_params %{
    "type" => "message",
    "text" => "Hello world",
    "thread_ts" => @slack_thread_ts,
    "channel" => @slack_channel,
    "user" => @slack_user_id
  }

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

    account
  end

  def fixture(:conversation, attrs) do
    params = Map.merge(%{status: "open"}, attrs)
    {:ok, conversation} = Conversations.create_conversation(params)

    conversation
  end

  def fixture(:slack_conversation_thread, attrs) do
    params =
      Map.merge(
        %{
          slack_thread_ts: @slack_thread_ts,
          slack_channel: @slack_channel
        },
        attrs
      )

    {:ok, thread} = SlackConversationThreads.create_slack_conversation_thread(params)

    thread
  end

  def fixture(:authorization, account_id, attrs) do
    params = Map.merge(@auth_params, attrs)
    {:ok, auth} = SlackAuthorizations.create_or_update(account_id, params)

    auth
  end

  setup %{conn: conn} do
    account = fixture(:account)
    conversation = fixture(:conversation, %{account_id: account.id})

    thread =
      fixture(:slack_conversation_thread, %{
        account_id: account.id,
        conversation_id: conversation.id
      })

    auth = fixture(:authorization, account.id, %{account_id: account.id})
    user = %ChatApi.Users.User{email: "test@example.com", account_id: auth.account_id}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, thread: thread}
  end

  describe "authorization" do
    test "gets the authorization details if they exist", %{authed_conn: authed_conn} do
      resp = get(authed_conn, Routes.slack_path(authed_conn, :authorization), %{})

      assert %{
               "channel" => channel,
               "team_name" => team_name
             } = json_response(resp, 200)["data"]

      assert channel == @auth_params.channel
      assert team_name == @auth_params.team_name
    end

    test "returns nil if the authorization does not exist", %{conn: conn} do
      new_account = fixture(:account)
      user = %ChatApi.Users.User{email: "test@example.com", account_id: new_account.id}
      authed_conn = Pow.Plug.assign_current_user(conn, user, [])
      resp = get(authed_conn, Routes.slack_path(authed_conn, :authorization), %{})

      assert %{"data" => nil} = json_response(resp, 200)
    end
  end

  describe "webhook" do
    test "sends an event to the webhook", %{conn: conn, thread: thread} do
      account_id = thread.account_id

      # TODO: figure out a better way to handle Slack warnings in test mode
      assert capture_log(fn ->
               post(conn, Routes.slack_path(conn, :webhook), %{
                 "event" => @event_params
               })
             end)

      assert [%{body: body}] = Messages.list_messages(account_id)
      assert body == @event_params["text"]
    end
  end
end
