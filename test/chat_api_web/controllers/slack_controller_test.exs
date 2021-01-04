defmodule ChatApiWeb.SlackControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  import Mock

  alias ChatApi.Messages

  @email "customer@test.com"
  @slack_channel "#test"

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    customer = insert(:customer, account: account, email: @email)
    conversation = insert(:conversation, account: account, customer: customer)
    auth = insert(:slack_authorization, account: account, channel: @slack_channel)

    thread =
      insert(:slack_conversation_thread,
        conversation: conversation,
        account: account,
        slack_channel: @slack_channel
      )

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok,
     conn: conn,
     authed_conn: authed_conn,
     thread: thread,
     auth: auth,
     account: account,
     conversation: conversation,
     customer: customer,
     user: user}
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
    test "sends a new thread message event to the webhook from the primary channel", %{
      conn: conn,
      auth: auth,
      thread: thread
    } do
      account_id = thread.account_id

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => @slack_channel,
        "user" => auth.authed_user_id
      }

      post(conn, Routes.slack_path(conn, :webhook), %{
        "event" => event_params
      })

      assert [%{body: body}] = Messages.list_messages(account_id)
      assert body == event_params["text"]
    end

    test "updates the conversation with the assignee after the first agent reply", %{
      conn: conn,
      auth: auth,
      thread: thread,
      user: user
    } do
      account_id = thread.account_id

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => @slack_channel,
        "user" => auth.authed_user_id
      }

      slack_user = %{
        "profile" => %{"email" => user.email}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end do
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        assert [%{conversation: conversation}] = Messages.list_messages(account_id)
        assert conversation.assignee_id == user.id
        assert conversation.read
      end
    end

    test "sends a new thread message event to the webhook from a support channel without authorization",
         %{
           conn: conn,
           auth: auth,
           account: account,
           conversation: conversation
         } do
      slack_channel = "#support"

      thread =
        insert(:slack_conversation_thread,
          conversation: conversation,
          account: account,
          slack_channel: slack_channel
        )

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => slack_channel,
        "user" => auth.authed_user_id
      }

      post(conn, Routes.slack_path(conn, :webhook), %{
        "event" => event_params
      })

      assert [] = Messages.list_messages(account.id)
    end

    test "sends a new thread message event to the webhook from a support channel with authorization",
         %{
           conn: conn,
           account: account,
           conversation: conversation,
           customer: customer
         } do
      slack_channel = "#test-support-channel"

      auth =
        insert(:slack_authorization, account: account, channel: slack_channel, type: "support")

      thread =
        insert(:slack_conversation_thread,
          conversation: conversation,
          account: account,
          slack_channel: slack_channel
        )

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => slack_channel,
        "user" => auth.authed_user_id
      }

      slack_user = %{
        "profile" => %{"email" => customer.email}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end,
        send_message: fn _, _ ->
          # TODO: this prevents a new thread from being created, but we should include an
          # actual response payload so that we can test that a thread is successfully created
          {:ok, nil}
        end do
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        assert [%{body: body}] = Messages.list_messages(account.id)
        assert body == event_params["text"]
      end
    end

    test "sends a new thread message event to the webhook from an unknown channel", %{
      conn: conn,
      thread: thread,
      auth: auth
    } do
      account_id = thread.account_id

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => "C123UNKNOWN",
        "user" => auth.authed_user_id
      }

      post(conn, Routes.slack_path(conn, :webhook), %{
        "event" => event_params
      })

      assert [] = Messages.list_messages(account_id)
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
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        assert [%{body: body}] = Messages.list_messages(account.id)
        assert body == event_params["text"]
      end
    end

    test "sends a new message event to the webhook from an unknown channel", %{
      conn: conn,
      account: account
    } do
      authorization = insert(:slack_authorization, account: account, type: "support")

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "channel" => "C123UNKNOWN",
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
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        assert [] = Messages.list_messages(account.id)
      end
    end
  end
end
