defmodule ChatApiWeb.SlackControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  import Mock

  alias ChatApi.{Companies, Customers, Messages}
  alias ChatApi.Companies.Company

  @email "customer@test.com"
  @slack_channel "#test"
  @slack_team "demo"

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account, role: "admin")
    customer = insert(:customer, account: account, email: @email)
    inbox = insert(:inbox, account: account, is_primary: true)
    conversation = insert(:conversation, account: account, customer: customer, inbox: inbox)
    auth = insert(:slack_authorization, account: account, inbox: inbox, channel: @slack_channel)

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
     inbox: inbox,
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

    test "deletes the authorization if it exists", %{authed_conn: authed_conn, auth: auth} do
      resp = get(authed_conn, Routes.slack_path(authed_conn, :authorization), %{})

      # First verify that it exists
      assert %{
               "channel" => _channel,
               "team_name" => _team_name
             } = json_response(resp, 200)["data"]

      # Then, delete and verify it no longer exists
      resp = delete(authed_conn, Routes.slack_path(authed_conn, :delete, auth))

      assert response(resp, 204)

      resp = get(authed_conn, Routes.slack_path(authed_conn, :authorization), %{})

      assert %{"data" => nil} = json_response(resp, 200)
    end
  end

  describe "webhook" do
    test "sending a new thread message event to the webhook from the primary channel", %{
      conn: conn,
      auth: auth,
      thread: thread
    } do
      account_id = thread.account_id

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "ts" => "12345",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => @slack_channel,
        "team" => @slack_team,
        "user" => auth.authed_user_id
      }

      post(conn, Routes.slack_path(conn, :webhook), %{
        "event" => event_params
      })

      assert [%{body: body, source: "slack"}] = Messages.list_messages(account_id)
      assert body == event_params["text"]
    end

    test "sending a new thread message event to the webhook from the primary channel as a private note",
         %{
           conn: conn,
           auth: auth,
           thread: thread
         } do
      account_id = thread.account_id

      post(conn, Routes.slack_path(conn, :webhook), %{
        "event" => %{
          "type" => "message",
          "text" => ~S(\\ This should be private),
          "ts" => "12345",
          "thread_ts" => thread.slack_thread_ts,
          "channel" => @slack_channel,
          "team" => @slack_team,
          "user" => auth.authed_user_id
        }
      })

      assert [%{body: body, source: "slack", type: "note", private: true}] =
               Messages.list_messages(account_id)

      assert body == "This should be private"
    end

    test "sending a new thread message event to the webhook from the primary channel as a private note (alternative)",
         %{
           conn: conn,
           auth: auth,
           thread: thread
         } do
      account_id = thread.account_id

      post(conn, Routes.slack_path(conn, :webhook), %{
        "event" => %{
          "type" => "message",
          "text" => ";; This should be private",
          "ts" => "12345",
          "thread_ts" => thread.slack_thread_ts,
          "channel" => @slack_channel,
          "team" => @slack_team,
          "user" => auth.authed_user_id
        }
      })

      assert [%{body: body, source: "slack", type: "note", private: true}] =
               Messages.list_messages(account_id)

      assert body == "This should be private"
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
        "ts" => "12345",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => @slack_channel,
        "team" => @slack_team,
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

    test "sending a new thread message event to the webhook from a support channel without authorization",
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
        "ts" => "12345",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => slack_channel,
        "team" => @slack_team,
        "user" => auth.authed_user_id
      }

      post(conn, Routes.slack_path(conn, :webhook), %{
        "event" => event_params
      })

      assert [] = Messages.list_messages(account.id)
    end

    test "sending a new thread message event to the webhook from a support channel with authorization",
         %{
           conn: conn,
           account: account,
           inbox: inbox,
           conversation: conversation,
           customer: customer
         } do
      slack_channel = "#test-support-channel"
      slack_team_id = "T123TEST"

      auth =
        insert(:slack_authorization,
          account: account,
          inbox: inbox,
          channel: slack_channel,
          team_id: slack_team_id,
          type: "support"
        )

      thread =
        insert(:slack_conversation_thread,
          conversation: conversation,
          account: account,
          slack_channel: slack_channel
        )

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        # Jan 1, 2021
        "ts" => "1609459200.0000",
        "thread_ts" => thread.slack_thread_ts,
        "channel" => slack_channel,
        "team" => slack_team_id,
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

        assert [%{body: body, conversation: conversation, sent_at: sent_at, source: "slack"}] =
                 Messages.list_messages(account.id)

        assert sent_at == ~U[2021-01-01 00:00:00Z]
        assert body == event_params["text"]
        refute conversation.read
      end
    end

    test "sending a new thread message event to the webhook from an unknown channel", %{
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
        "team" => @slack_team,
        "user" => auth.authed_user_id
      }

      post(conn, Routes.slack_path(conn, :webhook), %{
        "event" => event_params
      })

      assert [] = Messages.list_messages(account_id)
    end

    test "sending a new thread message event to the webhook in response to a bot message should trigger a new thread",
         %{
           conn: conn,
           account: account
         } do
      authorization = insert(:slack_authorization, account: account, type: "support")

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "team" => authorization.team_id,
        # Jan 2, 2021
        "ts" => "1609545600.0000",
        # Jan 1, 2021
        "thread_ts" => "1609459200.0000",
        "channel" => authorization.channel_id,
        "user" => authorization.authed_user_id
      }

      slack_user = %{
        "real_name" => "Test User",
        "tz" => "America/New_York",
        "profile" => %{"email" => @email}
      }

      slack_bot_user = %{
        "id" => "B123",
        "name" => "Papercups Bot"
      }

      slack_bot_message = %{
        "text" => "This is a bot message",
        "bot_id" => "B123",
        "ts" => event_params["thread_ts"]
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end,
        retrieve_bot_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "bot" => slack_bot_user}}}
        end,
        retrieve_message: fn _, _, _ ->
          {:ok, %{body: %{"ok" => true, "messages" => [slack_bot_message]}}}
        end,
        retrieve_conversation_replies: fn _, _, _ ->
          {:ok, %{body: %{"ok" => true, "messages" => [slack_bot_message, event_params]}}}
        end,
        send_message: fn _, _ -> {:ok, nil} end do
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        messages = account.id |> Messages.list_messages() |> Enum.sort_by(& &1.sent_at, :asc)

        assert [%{body: body, conversation: conversation, source: "slack"}, reply] = messages
        assert %{source: "slack"} = conversation
        assert body == slack_bot_message["text"]
        assert reply.body == event_params["text"]
      end
    end

    test "sending a new thread message event to the webhook in response to a non-bot message should not do anything",
         %{
           conn: conn,
           account: account
         } do
      authorization = insert(:slack_authorization, account: account, type: "support")

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "team" => authorization.team_id,
        "thread_ts" => "12345",
        "channel" => authorization.channel_id,
        "user" => authorization.authed_user_id
      }

      slack_user = %{
        "real_name" => "Test User",
        "tz" => "America/New_York",
        "profile" => %{"email" => @email}
      }

      slack_bot_message = %{
        "text" => "This is a non-bot message",
        "user" => "U123TEST"
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end,
        retrieve_message: fn _, _, _ ->
          {:ok, %{body: %{"ok" => true, "messages" => [slack_bot_message]}}}
        end,
        retrieve_conversation_replies: fn _, _, _ ->
          {:ok, %{body: %{"ok" => true, "messages" => [slack_bot_message]}}}
        end,
        send_message: fn _, _ -> {:ok, nil} end do
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        assert [] = Messages.list_messages(account.id)
      end
    end

    test "sending a new message event to the webhook from the default support channel", %{
      conn: conn,
      account: account
    } do
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

        assert [%{body: body, conversation: conversation, source: "slack"}] =
                 Messages.list_messages(account.id)

        assert %{source: "slack"} = conversation
        assert body == event_params["text"]
      end
    end

    test "sending a new message event to the webhook from a private company channel", %{
      conn: conn,
      account: account
    } do
      authorization = insert(:slack_authorization, account: account, type: "support")

      company =
        insert(:company,
          account: account,
          name: "Slack Test Co",
          slack_channel_id: @slack_channel
        )

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "channel" => @slack_channel,
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

        assert [
                 %{
                   body: body,
                   customer_id: customer_id,
                   conversation: conversation,
                   source: "slack"
                 }
               ] = Messages.list_messages(account.id)

        assert %{company_id: company_id} = Customers.get_customer!(customer_id)
        assert %{source: "slack"} = conversation
        assert body == event_params["text"]
        assert company_id == company.id
      end
    end

    test "uses the correct Slack team_id from a shared external private company channel", %{
      conn: conn,
      account: account
    } do
      team_id = "T123TEST"

      authorization =
        insert(:slack_authorization, account: account, type: "support", team_id: team_id)

      company =
        insert(:company,
          account: account,
          name: "Slack Test Co",
          slack_channel_id: @slack_channel
        )

      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "channel" => @slack_channel,
        "team" => "T123EXTERNAL",
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
          "event" => event_params,
          "is_ext_shared_channel" => true,
          "team_id" => team_id
        })

        assert [
                 %{
                   body: body,
                   customer_id: customer_id,
                   conversation: conversation,
                   source: "slack"
                 }
               ] = Messages.list_messages(account.id)

        assert %{company_id: company_id} = Customers.get_customer!(customer_id)
        assert %{source: "slack"} = conversation
        assert body == event_params["text"]
        assert company_id == company.id
      end
    end

    test "uses the payload team_id when the event is missing a team field", %{
      conn: conn,
      account: account,
      auth: auth,
      thread: thread
    } do
      event_params = %{
        "type" => "message",
        "text" => "hello world #{System.unique_integer([:positive])}",
        "channel" => @slack_channel,
        "user" => auth.authed_user_id,
        "thread_ts" => thread.slack_thread_ts,
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
          "event" => event_params,
          "is_ext_shared_channel" => false,
          "team_id" => @slack_team
        })

        assert [%{body: body, source: "slack"}] = Messages.list_messages(account.id)
        assert body == event_params["text"]
      end
    end

    test "sending a new message event to the webhook from an unknown channel", %{
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

    test "sending a new channel_join event to the webhook", %{
      conn: conn,
      account: account
    } do
      authorization = insert(:slack_authorization, account: account, type: "support")
      channel_id = "C123TEST"

      event_params = %{
        "type" => "message",
        "subtype" => "channel_join",
        "text" => "@papercups has joined the channel",
        "channel" => channel_id,
        "team" => authorization.team_id,
        "user" => authorization.bot_user_id,
        "inviter" => authorization.authed_user_id,
        "ts" => "1234.56789"
      }

      slack_channel_info = %{
        "name" => "test",
        "purpose" => %{"value" => "To test channel_join"},
        "topic" => %{"value" => "Testing"}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_channel_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "channel" => slack_channel_info}}}
        end,
        send_message: fn _, _ -> {:ok, nil} end do
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        assert [] = Messages.list_messages(account.id)
        assert %Company{} = Companies.find_by_slack_channel(channel_id)
      end
    end

    test "sending a new group_join event to the webhook", %{
      conn: conn,
      account: account
    } do
      authorization = insert(:slack_authorization, account: account, type: "support")
      channel_id = "G123TEST"

      event_params = %{
        "type" => "message",
        "subtype" => "group_join",
        "text" => "@papercups has joined the channel",
        "channel" => channel_id,
        "team" => authorization.team_id,
        "user" => authorization.bot_user_id,
        "inviter" => authorization.authed_user_id,
        "ts" => "1234.56789"
      }

      slack_channel_info = %{
        "name" => "test",
        "purpose" => %{"value" => "To test group_join"},
        "topic" => %{"value" => "Testing"}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_channel_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "channel" => slack_channel_info}}}
        end,
        send_message: fn _, _ -> {:ok, nil} end do
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        assert [] = Messages.list_messages(account.id)
        assert %Company{} = Companies.find_by_slack_channel(channel_id)
      end
    end

    test "sending a new channel_join event to the webhook from the primary support channel does not create new company",
         %{
           conn: conn,
           account: account
         } do
      authorization = insert(:slack_authorization, account: account, type: "support")

      event_params = %{
        "type" => "message",
        "subtype" => "channel_join",
        "text" => "@papercups has joined the channel",
        "channel" => authorization.channel_id,
        "team" => authorization.team_id,
        "user" => authorization.bot_user_id,
        "inviter" => authorization.authed_user_id,
        "ts" => "1234.56789"
      }

      slack_channel_info = %{
        "name" => "test",
        "purpose" => %{"value" => "To test channel_join"},
        "topic" => %{"value" => "Testing"}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_channel_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "channel" => slack_channel_info}}}
        end,
        send_message: fn _, _ -> {:ok, nil} end do
        post(conn, Routes.slack_path(conn, :webhook), %{
          "event" => event_params
        })

        assert [] = Messages.list_messages(account.id)
        refute Companies.find_by_slack_channel(authorization.channel_id)
      end
    end
  end
end
