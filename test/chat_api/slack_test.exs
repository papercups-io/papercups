defmodule ChatApi.SlackTest do
  use ChatApi.DataCase

  import ExUnit.CaptureLog
  import ChatApi.Factory
  import Mock

  alias ChatApi.{
    Conversations,
    Messages,
    Slack,
    SlackConversationThreads,
    Users
  }

  describe "Slack.Token" do
    test "Token.is_valid_access_token?/1 checks the validity of an access token" do
      assert Slack.Token.is_valid_access_token?("invalid") == false
      assert Slack.Token.is_valid_access_token?("xoxb-xxx-xxxxx-xxx") == true
    end
  end

  @slack_user_id "U123TEST"
  @slack_channel_id "C123TEST"

  describe "Slack.Notification" do
    setup do
      account = insert(:account)
      auth = insert(:slack_authorization, account: account, type: "support")
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)

      thread =
        insert(:slack_conversation_thread,
          account: account,
          conversation: conversation,
          slack_channel: @slack_channel_id
        )

      {:ok,
       conversation: conversation,
       auth: auth,
       account: account,
       customer: customer,
       thread: thread}
    end

    test "Notification.notify_slack_channel/2 sends a thread reply notification", %{
      account: account,
      auth: auth,
      conversation: conversation,
      thread: thread
    } do
      user = insert(:user, account: account, email: "user@user.com")

      profile =
        insert(:user_profile,
          user: user,
          display_name: "Test User",
          profile_photo_url: "https://image.com"
        )

      message =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          customer: nil
        )

      with_mock ChatApi.Slack.Client,
        send_message: fn msg, _ ->
          {:ok, %{body: Map.merge(%{"ok" => true}, msg)}}
        end do
        message = Messages.get_message!(message.id)
        assert :ok = Slack.Notification.notify_slack_channel(@slack_channel_id, message)

        assert_called(Slack.Client.send_message(:_, :_))

        assert_called(
          Slack.Client.send_message(
            %{
              "text" => message.body,
              "channel" => thread.slack_channel,
              "thread_ts" => thread.slack_thread_ts,
              "username" => profile.display_name,
              "icon_url" => profile.profile_photo_url
            },
            auth.access_token
          )
        )
      end
    end

    test "Notification.notify_slack_channel/2 sends a thread reply notification for users without profile info",
         %{
           account: account,
           auth: auth,
           conversation: conversation,
           thread: thread
         } do
      user = insert(:user, account: account, email: "user@user.com")

      message =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          customer: nil
        )

      with_mock ChatApi.Slack.Client,
        send_message: fn msg, _ ->
          {:ok, %{body: Map.merge(%{"ok" => true}, msg)}}
        end do
        message = Messages.get_message!(message.id)
        assert :ok = Slack.Notification.notify_slack_channel(@slack_channel_id, message)

        assert_called(Slack.Client.send_message(:_, :_))

        assert_called(
          Slack.Client.send_message(
            %{
              "text" => message.body,
              "channel" => thread.slack_channel,
              "thread_ts" => thread.slack_thread_ts,
              "username" => user.email
            },
            auth.access_token
          )
        )
      end
    end

    test "Notification.notify_slack_channel/2 does not send a thread reply if channel is not found",
         %{
           account: account,
           customer: customer,
           conversation: conversation
         } do
      message = insert(:message, account: account, conversation: conversation, customer: customer)

      with_mock ChatApi.Slack.Client,
        send_message: fn msg, _ ->
          {:ok, %{body: Map.merge(%{"ok" => true}, msg)}}
        end do
        assert :ok = Slack.Notification.notify_slack_channel("C123UNKNOWN", message)

        assert_not_called(Slack.Client.send_message(:_, :_))
      end
    end

    test "Notification.validate_send_to_primary_channel/2 returns :ok if the message is the initial message",
         %{thread: thread} do
      assert :ok =
               Slack.Notification.validate_send_to_primary_channel(thread, is_first_message: true)

      assert :ok =
               Slack.Notification.validate_send_to_primary_channel(nil, is_first_message: true)
    end

    test "Notification.validate_send_to_primary_channel/2 returns :ok if a thread already exists",
         %{thread: thread} do
      assert :ok =
               Slack.Notification.validate_send_to_primary_channel(thread, is_first_message: false)
    end

    test "Notification.validate_send_to_primary_channel/2 returns :error if the message when the message is not an initial message and a thread does not exist" do
      assert :error =
               Slack.Notification.validate_send_to_primary_channel(nil, is_first_message: false)
    end
  end

  describe "Slack.Helpers" do
    setup do
      account = insert(:account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)
      thread = insert(:slack_conversation_thread, account: account, conversation: conversation)

      {:ok, conversation: conversation, account: account, customer: customer, thread: thread}
    end

    test "Helpers.get_message_text/1 returns subject for initial slack thread",
         %{conversation: conversation, customer: customer} do
      text =
        Slack.Helpers.get_message_text(%{
          customer: customer,
          text: "Test message",
          conversation_id: conversation.id,
          type: :customer,
          thread: nil
        })

      assert String.contains?(text, customer.email)
      assert String.contains?(text, conversation.id)
      assert String.contains?(text, "Reply to this thread to start chatting")
    end

    test "Helpers.get_message_text/1 returns subject for slack reply",
         %{conversation: conversation, customer: customer, thread: thread} do
      assert Slack.Helpers.get_message_text(%{
               text: "Test message",
               conversation_id: conversation.id,
               customer: customer,
               type: :agent,
               thread: thread
             }) ==
               "*:female-technologist: Agent*: Test message"

      assert Slack.Helpers.get_message_text(%{
               text: "Test message",
               conversation_id: conversation.id,
               customer: customer,
               type: :customer,
               thread: thread
             }) ==
               "*:wave: #{customer.email}*: Test message"

      assert_raise ArgumentError, fn ->
        Slack.Helpers.get_message_text(%{
          text: "Test message",
          conversation_id: conversation.id,
          customer: customer,
          type: :invalid,
          thread: thread
        })
      end
    end

    test "Helpers.get_message_payload/2 returns payload for initial slack thread",
         %{customer: customer, thread: thread} do
      text = "Hello world"
      customer_email = "*Email:*\n#{customer.email}"
      channel = thread.slack_channel

      assert %{
               "blocks" => [
                 %{
                   "text" => %{
                     "text" => ^text
                   }
                 },
                 %{
                   "fields" => [
                     %{
                       "text" => "*Name:*\nAnonymous User"
                     },
                     %{
                       "text" => ^customer_email
                     },
                     %{
                       "text" => "*URL:*\nN/A"
                     },
                     %{
                       "text" => "*Browser:*\nN/A"
                     },
                     %{
                       "text" => "*OS:*\nN/A"
                     },
                     %{
                       "text" => "*Timezone:*\nN/A"
                     }
                   ]
                 }
               ],
               "channel" => ^channel
             } =
               Slack.Helpers.get_message_payload(text, %{
                 channel: channel,
                 customer: customer,
                 thread: nil
               })
    end

    test "Helpers.get_message_payload/2 returns payload for slack reply", %{thread: thread} do
      text = "Hello world"
      ts = thread.slack_thread_ts
      channel = thread.slack_channel
      customer_message = insert(:message, user: nil)
      user_message = insert(:message, customer: nil)

      assert %{
               "channel" => ^channel,
               "text" => ^text,
               "thread_ts" => ^ts,
               "reply_broadcast" => false
             } =
               Slack.Helpers.get_message_payload(text, %{
                 channel: channel,
                 thread: thread,
                 customer: nil,
                 message: customer_message
               })

      assert %{
               "channel" => ^channel,
               "text" => ^text,
               "thread_ts" => ^ts,
               "reply_broadcast" => false
             } =
               Slack.Helpers.get_message_payload(text, %{
                 channel: channel,
                 thread: thread,
                 customer: nil,
                 message: user_message
               })
    end

    test "Helpers.extract_slack_conversation_thread_info/1 extracts thread info from slack response" do
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      assert %{slack_channel: ^channel, slack_thread_ts: ^ts} =
               Slack.Helpers.extract_slack_conversation_thread_info(response)
    end

    test "Helpers.extract_slack_conversation_thread_info/1 raises if the slack response has ok=false" do
      response = %{body: %{"ok" => false}}

      assert capture_log(fn ->
               assert_raise RuntimeError, fn ->
                 Slack.Helpers.extract_slack_conversation_thread_info(response)
               end
             end) =~ "Error sending Slack message"
    end

    test "Helpers.extract_slack_user_email/1 extracts user's email from slack response" do
      email = "test@test.com"
      response = %{body: %{"ok" => true, "user" => %{"profile" => %{"email" => email}}}}

      assert email = Slack.Helpers.extract_slack_user_email(response)
    end

    test "Helpers.extract_slack_user_email/1 raises if the slack response has ok=false" do
      response = %{body: %{"ok" => false, "user" => nil}}

      assert capture_log(fn ->
               assert_raise RuntimeError, fn ->
                 Slack.Helpers.extract_slack_user_email(response)
               end
             end) =~ "Error retrieving user info"
    end

    test "Helpers.create_new_slack_conversation_thread/2 creates a new thread and assigns the primary user",
         %{conversation: conversation, account: account} do
      %{account_id: account_id, id: id} = conversation
      primary_user = insert(:user, account: account)
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      {:ok, thread} = Slack.Helpers.create_new_slack_conversation_thread(id, response)

      assert %SlackConversationThreads.SlackConversationThread{
               slack_channel: ^channel,
               slack_thread_ts: ^ts,
               account_id: ^account_id,
               conversation_id: ^id
             } = thread

      conversation = Conversations.get_conversation!(id)

      assert conversation.assignee_id == primary_user.id
    end

    test "Helpers.create_new_slack_conversation_thread/2 raises if no primary user exists",
         %{conversation: conversation} do
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      assert_raise RuntimeError, fn ->
        Slack.Helpers.create_new_slack_conversation_thread(conversation.id, response)
      end
    end

    test "Helpers.get_conversation_primary_user_id/2 gets the primary user of the associated account" do
      account = insert(:account)
      user = insert(:user, account: account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)
      conversation = Conversations.get_conversation_with!(conversation.id, account: :users)

      assert Slack.Helpers.get_conversation_primary_user_id(conversation) == user.id
    end

    test "Helpers.fetch_valid_user/1 reject disabled users and fetch the oldest user.",
         %{account: account} do
      {:ok, disabled_user} =
        insert(:user, account: account)
        |> Users.disable_user()

      primary_user = insert(:user, account: account)

      # Make sure that secondary_user is inserted later.
      :timer.sleep(1000)
      secondary_user = insert(:user, account: account)

      users = [disabled_user, secondary_user, primary_user]
      assert primary_user.id === Slack.Helpers.fetch_valid_user(users)
    end

    test "Helpers.identify_customer/1 returns the message sender type", %{account: account} do
      jane = insert(:customer, account: account, name: "Jane", email: "jane@jane.com")
      bob = insert(:customer, account: account, email: "bob@bob.com", name: nil)
      test = insert(:customer, account: account, name: "Test User", email: nil)
      anon = insert(:customer, account: account, name: nil, email: nil)

      assert Slack.Helpers.identify_customer(jane) == "Jane (jane@jane.com)"
      assert Slack.Helpers.identify_customer(bob) == "bob@bob.com"
      assert Slack.Helpers.identify_customer(test) == "Test User"
      assert Slack.Helpers.identify_customer(anon) == "Anonymous User"
    end

    test "Helpers.get_message_type/1 returns the message sender type" do
      customer_message = insert(:message, user: nil)
      user_message = insert(:message, customer: nil)

      assert :customer = Slack.Helpers.get_message_type(customer_message)
      assert :agent = Slack.Helpers.get_message_type(user_message)
    end

    test "Helpers.format_sender_id!/3 gets an existing user_id", %{account: account} do
      authorization = insert(:slack_authorization, account: account)
      _customer = insert(:customer, account: account, email: "customer@customer.com")
      user = insert(:user, account: account, email: "user@user.com")

      slack_user = %{
        "real_name" => "Test User",
        "tz" => "America/New_York",
        "profile" => %{"email" => "user@user.com", "real_name" => "Test User"}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end do
        refute Slack.Helpers.find_matching_customer(authorization, @slack_user_id)
        assert %{id: user_id} = Slack.Helpers.find_matching_user(authorization, @slack_user_id)
        assert user_id == user.id

        assert %{"user_id" => ^user_id} =
                 Slack.Helpers.format_sender_id!(authorization, @slack_user_id, @slack_channel_id)
      end
    end

    test "Helpers.format_sender_id!/3 gets an existing customer_id", %{account: account} do
      authorization = insert(:slack_authorization, account: account)
      customer = insert(:customer, account: account, email: "customer@customer.com")
      _user = insert(:user, account: account, email: "user@user.com")

      slack_user = %{
        "real_name" => "Test Customer",
        "tz" => "America/New_York",
        "profile" => %{"email" => "customer@customer.com", "real_name" => "Test Customer"}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end do
        assert %{id: customer_id} =
                 Slack.Helpers.find_matching_customer(authorization, @slack_user_id)

        refute Slack.Helpers.find_matching_user(authorization, @slack_user_id)
        assert customer_id == customer.id

        assert %{"customer_id" => ^customer_id} =
                 Slack.Helpers.format_sender_id!(authorization, @slack_user_id, @slack_channel_id)
      end
    end

    test "Helpers.format_sender_id!/3 creates a new customer_id if necessary", %{account: account} do
      authorization = insert(:slack_authorization, account: account)
      _customer = insert(:customer, account: account, email: "customer@customer.com")
      _user = insert(:user, account: account, email: "user@user.com")

      company =
        insert(:company,
          account: account,
          name: "Slack Test Co",
          slack_channel_id: @slack_channel_id
        )

      slack_user = %{
        "real_name" => "Test Customer",
        "tz" => "America/New_York",
        # New customer email
        "profile" => %{"email" => "new@customer.com", "real_name" => "Test Customer"}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end do
        refute Slack.Helpers.find_matching_customer(authorization, @slack_user_id)
        refute Slack.Helpers.find_matching_user(authorization, @slack_user_id)

        assert %{"customer_id" => customer_id} =
                 Slack.Helpers.format_sender_id!(authorization, @slack_user_id, @slack_channel_id)

        customer = ChatApi.Customers.get_customer!(customer_id)

        assert customer.email == "new@customer.com"
        assert customer.name == "Test Customer"
        assert customer.company_id == company.id
      end
    end

    test "Helpers.create_or_update_customer_from_slack_user_id/3 creates or updates the customer",
         %{account: account} do
      authorization = insert(:slack_authorization, account: account)

      slack_user = %{
        "real_name" => "Test Customer",
        "tz" => "America/New_York",
        # New customer email
        "profile" => %{"email" => "new@customer.com", "real_name" => "Test Customer"}
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end do
        {:ok, new_customer} =
          Slack.Helpers.create_or_update_customer_from_slack_user_id(
            authorization,
            @slack_user_id,
            @slack_channel_id
          )

        assert new_customer.email == "new@customer.com"
        assert new_customer.name == "Test Customer"

        company =
          insert(:company,
            account: account,
            name: "Slack Test Co",
            slack_channel_id: @slack_channel_id
          )

        {:ok, updated_customer} =
          Slack.Helpers.create_or_update_customer_from_slack_user_id(
            authorization,
            @slack_user_id,
            @slack_channel_id
          )

        assert updated_customer.id == new_customer.id
        assert updated_customer.company_id == company.id
        assert updated_customer.email == "new@customer.com"
        assert updated_customer.name == "Test Customer"
      end
    end

    test "Helpers.sanitize_slack_message/2 formats user IDs properly", %{account: account} do
      authorization = insert(:slack_authorization, account: account)
      slack_user_id_with_username_only = "U123USERNAMEONLY"
      slack_user_id_with_real_name = "U123WITHREALNAME"
      slack_user_id_with_display_name = "U123WITHDISPLAYNAME"

      slack_users_by_id = %{
        slack_user_id_with_username_only => %{
          "id" => slack_user_id_with_username_only,
          "name" => "alexr",
          "real_name" => "Alex Reichert",
          "tz" => "America/New_York"
        },
        slack_user_id_with_real_name => %{
          "id" => slack_user_id_with_real_name,
          "name" => "alexr",
          "real_name" => "Alex Reichert",
          "tz" => "America/New_York",
          "profile" => %{"email" => "new@customer.com", "real_name" => "Alex Reichert"}
        },
        slack_user_id_with_display_name => %{
          "id" => slack_user_id_with_display_name,
          "name" => "alexr",
          "real_name" => "Alex Reichert",
          "tz" => "America/New_York",
          "profile" => %{
            "email" => "new@customer.com",
            "real_name" => "Alex Reichert",
            "display_name" => "Alex"
          }
        }
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn slack_user_id, _ ->
          {:ok, %{body: %{"ok" => true, "user" => Map.get(slack_users_by_id, slack_user_id)}}}
        end do
        assert "What's up, @alexr?" =
                 Slack.Helpers.sanitize_slack_message(
                   "What's up, <@#{slack_user_id_with_username_only}>?",
                   authorization
                 )

        assert "Hi there, @Alex Reichert!" =
                 Slack.Helpers.sanitize_slack_message(
                   "Hi there, <@#{slack_user_id_with_real_name}>!",
                   authorization
                 )

        assert "How's it going, @Alex?" =
                 Slack.Helpers.sanitize_slack_message(
                   "How's it going, <@#{slack_user_id_with_display_name}>?",
                   authorization
                 )
      end
    end

    test "Helpers.sanitize_slack_message/2 doesn't do anything for unrecognized user IDs", %{
      account: account
    } do
      authorization = insert(:slack_authorization, account: account)

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, "Something went wrong!"}
        end do
        assert capture_log(fn ->
                 assert "What's up, <@U123INVALID>?" =
                          Slack.Helpers.sanitize_slack_message(
                            "What's up, <@U123INVALID>?",
                            authorization
                          )
               end) =~ "Unable to retrieve Slack username"
      end
    end

    test "Helpers.sanitize_slack_message/2 formats links properly", %{account: account} do
      authorization = insert(:slack_authorization, account: account)

      assert "[https://google.com](https://google.com)" =
               Slack.Helpers.sanitize_slack_message("<https://google.com>", authorization)

      assert "[google.com](http://google.com)" =
               Slack.Helpers.sanitize_slack_message(
                 "<http://google.com|google.com>",
                 authorization
               )

      assert "[www.google.com](http://google.com)" =
               Slack.Helpers.sanitize_slack_message(
                 "<http://google.com|www.google.com>",
                 authorization
               )

      assert "[check it out!](https://google.com)" =
               Slack.Helpers.sanitize_slack_message(
                 "<https://google.com|check it out!>",
                 authorization
               )
    end

    test "Helpers.sanitize_slack_message/2 formats mailto links properly", %{account: account} do
      authorization = insert(:slack_authorization, account: account)

      assert "[alex@test.com](mailto:alex@test.com)" =
               Slack.Helpers.sanitize_slack_message(
                 "<mailto:alex@test.com|alex@test.com>",
                 authorization
               )

      assert "[alex123+papercups@test.com](mailto:alex123+papercups@test.com)" =
               Slack.Helpers.sanitize_slack_message(
                 "<mailto:alex123+papercups@test.com|alex123+papercups@test.com>",
                 authorization
               )
    end

    test "Helpers.sanitize_slack_message/2 doesn't modify messages without urls, mailto links, or user IDs",
         %{account: account} do
      authorization = insert(:slack_authorization, account: account)

      [
        "Hi there!",
        "<this is not a link or user ID>",
        "@papercups is awesome",
        "Yo | yo | yo",
        "<links-must-start-with-http.com>",
        # TODO: add support for formatting this one:
        "<#C123> is a link to a channel"
      ]
      |> Enum.each(fn text ->
        assert ^text = Slack.Helpers.sanitize_slack_message(text, authorization)
      end)
    end

    test "Helpers.is_bot_message?/1 checks if the Slack message payload is from a bot" do
      bot_message = %{"bot_id" => "B123", "text" => "I am a bot"}
      nil_bot_message = %{"bot_id" => nil, "text" => "I am not a bot"}
      non_bot_message = %{"text" => "I am also not a bot"}

      assert Slack.Helpers.is_bot_message?(bot_message)
      refute Slack.Helpers.is_bot_message?(nil_bot_message)
      refute Slack.Helpers.is_bot_message?(non_bot_message)
    end
  end
end
