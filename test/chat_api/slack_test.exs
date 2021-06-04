defmodule ChatApi.SlackTest do
  use ChatApi.DataCase

  import ExUnit.CaptureLog
  import ChatApi.Factory
  import Mock

  alias ChatApi.{
    Messages,
    Slack,
    SlackConversationThreads
  }

  describe "Slack.Token" do
    test "Token.is_valid_access_token?/1 checks the validity of an access token" do
      assert Slack.Token.is_valid_access_token?("invalid") == false
      assert Slack.Token.is_valid_access_token?("xoxb-xxx-xxxxx-xxx") == true
    end
  end

  @slack_user_id "U123TEST"
  @slack_channel_id "C123TEST"

  describe "Slack.Validation" do
    test "Validation.validate_authorization_channel_id/3 checks if another integration has the same Slack channel ID" do
      account = insert(:account)

      insert(:slack_authorization,
        account: account,
        type: "reply",
        channel_id: @slack_channel_id
      )

      other_channel_id = "C123OTHER"
      other_account_id = insert(:account).id

      # :ok if we're connecting to a different channel
      assert :ok =
               Slack.Validation.validate_authorization_channel_id(
                 other_channel_id,
                 account.id,
                 "support"
               )

      # :ok if we're reconnecting to the same integration type
      assert :ok =
               Slack.Validation.validate_authorization_channel_id(
                 @slack_channel_id,
                 account.id,
                 "reply"
               )

      # :error if connecting to a channel that another account has already linked
      assert {:error, :duplicate_channel_id} =
               Slack.Validation.validate_authorization_channel_id(
                 @slack_channel_id,
                 other_account_id,
                 "reply"
               )

      # :error if we're connecting to a new integration type with the same channel
      assert {:error, :duplicate_channel_id} =
               Slack.Validation.validate_authorization_channel_id(
                 @slack_channel_id,
                 account.id,
                 "support"
               )
    end
  end

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

    test "Notification.format_slack_message_text/1 formats messages without attachments",
         %{
           account: account,
           customer: customer,
           conversation: conversation
         } do
      message =
        insert(:message,
          account: account,
          conversation: conversation,
          customer: customer
        )

      assert Slack.Notification.format_slack_message_text(message) =~ message.body
    end

    test "Notification.format_slack_message_text/1 formats messages with attachments",
         %{
           account: account,
           customer: customer,
           conversation: conversation
         } do
      message =
        insert(:message,
          account: account,
          conversation: conversation,
          customer: customer,
          attachments: [
            insert(:file, filename: "Test File", file_url: "https://file.jpg")
          ]
        )

      assert Slack.Notification.format_slack_message_text(message) =~
               "<https://file.jpg|Test File>"

      assert Slack.Notification.format_slack_message_text(message) =~
               message.body
    end

    test "Notification.format_slack_message_text/1 formats messages with attachments and no body text",
         %{
           account: account,
           customer: customer,
           conversation: conversation
         } do
      message =
        insert(:message,
          account: account,
          conversation: conversation,
          customer: customer,
          body: nil,
          attachments: [
            insert(:file, filename: "Test File", file_url: "https://file.jpg")
          ]
        )

      assert Slack.Notification.format_slack_message_text(message) =~
               "<https://file.jpg|Test File>"
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
      assert {:error, :conversation_exists_without_thread} =
               Slack.Notification.validate_send_to_primary_channel(nil, is_first_message: false)
    end
  end

  describe "Slack.Helpers" do
    setup do
      account = insert(:account)
      authorization = insert(:slack_authorization, account: account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)
      thread = insert(:slack_conversation_thread, account: account, conversation: conversation)

      {:ok,
       conversation: conversation,
       account: account,
       authorization: authorization,
       customer: customer,
       thread: thread}
    end

    test "Helpers.get_message_text/1 returns subject for initial slack thread",
         %{authorization: authorization, conversation: conversation, customer: customer} do
      message = insert(:message, customer: customer, user: nil)

      text =
        Slack.Helpers.get_message_text(%{
          conversation: conversation,
          message: message,
          authorization: authorization,
          thread: nil
        })

      assert String.contains?(text, customer.email)
      assert String.contains?(text, conversation.id)
      assert String.contains?(text, "Reply to this thread to start chatting")
    end

    test "Helpers.get_message_text/1 returns subject for slack reply",
         %{
           account: account,
           authorization: authorization,
           conversation: conversation,
           customer: customer,
           thread: thread
         } do
      user = insert(:user, account: account, email: "test@test.com")

      assert Slack.Helpers.get_message_text(%{
               conversation: conversation,
               message: insert(:message, user: user, customer: nil, body: "Test message"),
               authorization: authorization,
               thread: thread
             }) ==
               "*:female-technologist: #{user.email}*: Test message"

      assert Slack.Helpers.get_message_text(%{
               conversation: conversation,
               message: insert(:message, user: nil, customer: customer, body: "Test message"),
               authorization: authorization,
               thread: thread
             }) ==
               "*:wave: #{customer.email}*: Test message"

      assert capture_log(fn ->
               assert Slack.Helpers.get_message_text(%{
                        conversation: conversation,
                        message: insert(:message, user: nil, customer: nil, body: "Test message"),
                        authorization: authorization,
                        thread: thread
                      }) == "Test message"
             end) =~ "Unrecognized message format"
    end

    test "Helpers.get_message_payload/2 returns payload for initial slack thread",
         %{customer: customer, conversation: conversation, thread: thread} do
      text = "Hello world"
      customer_email = "*Email:*\n#{customer.email}"
      conversation_id = conversation.id
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
                     },
                     %{"text" => "*Status:*\n:wave: Unhandled"}
                   ]
                 },
                 %{"type" => "divider"},
                 %{
                   "elements" => [
                     %{
                       "action_id" => "close_conversation",
                       "style" => "primary",
                       "text" => %{"text" => "Mark as resolved", "type" => "plain_text"},
                       "type" => "button",
                       "value" => ^conversation_id
                     }
                   ],
                   "type" => "actions"
                 }
               ],
               "channel" => ^channel
             } =
               Slack.Helpers.get_message_payload(text, %{
                 channel: channel,
                 conversation: conversation,
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

    test "Extractor.extract_slack_conversation_thread_info!/1 extracts thread info from slack response" do
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      assert %{slack_channel: ^channel, slack_thread_ts: ^ts} =
               Slack.Extractor.extract_slack_conversation_thread_info!(response)
    end

    test "Extractor.extract_slack_conversation_thread_info!/1 raises if the slack response has ok=false" do
      response = %{body: %{"ok" => false}}

      assert capture_log(fn ->
               assert_raise RuntimeError, fn ->
                 Slack.Extractor.extract_slack_conversation_thread_info!(response)
               end
             end) =~ "Error sending Slack message"
    end

    test "Extractor.extract_slack_user_email!/1 extracts user's email from slack response" do
      email = "test@test.com"
      response = %{body: %{"ok" => true, "user" => %{"profile" => %{"email" => email}}}}

      assert email == Slack.Extractor.extract_slack_user_email!(response)
    end

    test "Extractor.extract_slack_user_email!/1 raises if the slack response has ok=false" do
      response = %{body: %{"ok" => false, "user" => nil}}

      assert capture_log(fn ->
               assert_raise RuntimeError, fn ->
                 Slack.Extractor.extract_slack_user_email!(response)
               end
             end) =~ "Error retrieving user info"
    end

    test "Helpers.create_new_slack_conversation_thread/2 creates a new thread", %{
      conversation: conversation
    } do
      %{account_id: account_id, id: id} = conversation
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      {:ok,
       %SlackConversationThreads.SlackConversationThread{
         slack_channel: ^channel,
         slack_thread_ts: ^ts,
         account_id: ^account_id,
         conversation_id: ^id
       }} = Slack.Helpers.create_new_slack_conversation_thread(id, response)
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

    test "Helpers.format_sender_id_v2!/3 gets an existing user_id", %{account: account} do
      authorization = insert(:slack_authorization, account: account)
      _customer = insert(:customer, account: account, email: "customer@customer.com")
      user = insert(:user, account: account, email: "user@user.com")

      slack_user = %{
        "real_name" => "Test User",
        "tz" => "America/New_York",
        "profile" => %{"email" => "user@user.com", "real_name" => "Test User"}
      }

      slack_event = %{
        "type" => "message",
        "channel" => @slack_channel_id,
        "user" => @slack_user_id
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end do
        refute Slack.Helpers.find_matching_customer(authorization, @slack_user_id)
        assert %{id: user_id} = Slack.Helpers.find_matching_user(authorization, @slack_user_id)
        assert user_id == user.id

        assert %{"user_id" => ^user_id} =
                 Slack.Helpers.format_sender_id_v2!(authorization, slack_event)
      end
    end

    test "Helpers.format_sender_id_v2!/3 gets an existing customer_id", %{account: account} do
      authorization = insert(:slack_authorization, account: account)
      customer = insert(:customer, account: account, email: "customer@customer.com")
      _user = insert(:user, account: account, email: "user@user.com")

      slack_user = %{
        "real_name" => "Test Customer",
        "tz" => "America/New_York",
        "profile" => %{"email" => "customer@customer.com", "real_name" => "Test Customer"}
      }

      slack_event = %{
        "type" => "message",
        "channel" => @slack_channel_id,
        "user" => @slack_user_id
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
                 Slack.Helpers.format_sender_id_v2!(authorization, slack_event)
      end
    end

    test "Helpers.format_sender_id_v2!/3 creates a new customer_id if necessary", %{
      account: account
    } do
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

      slack_event = %{
        "type" => "message",
        "channel" => @slack_channel_id,
        "user" => @slack_user_id
      }

      with_mock ChatApi.Slack.Client,
        retrieve_user_info: fn _, _ ->
          {:ok, %{body: %{"ok" => true, "user" => slack_user}}}
        end do
        refute Slack.Helpers.find_matching_customer(authorization, @slack_user_id)
        refute Slack.Helpers.find_matching_user(authorization, @slack_user_id)

        assert %{"customer_id" => customer_id} =
                 Slack.Helpers.format_sender_id_v2!(authorization, slack_event)

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

    test "Helpers.sanitize_slack_message/2 removes private note indicator prefixes",
         %{account: account} do
      authorization = insert(:slack_authorization, account: account)

      assert "reply" = Slack.Helpers.sanitize_slack_message("reply", authorization)
      assert "note" = Slack.Helpers.sanitize_slack_message("\\\\ note", authorization)
      assert "note" = Slack.Helpers.sanitize_slack_message(~S(\\ note), authorization)
      assert "note" = Slack.Helpers.sanitize_slack_message(";; note", authorization)
      assert "note" = Slack.Helpers.sanitize_slack_message(~S(\\note), authorization)
      assert "note" = Slack.Helpers.sanitize_slack_message(";;note", authorization)
    end

    test "Helpers.parse_message_type_params/1 removes private note indicator prefixes" do
      assert Slack.Helpers.parse_message_type_params("reply") == %{}
      assert Slack.Helpers.parse_message_type_params("reply \\\\ reply") == %{}
      assert Slack.Helpers.parse_message_type_params("reply;;reply") == %{}

      assert %{"private" => true, "type" => "note"} =
               Slack.Helpers.parse_message_type_params("\\\\ note")

      assert %{"private" => true, "type" => "note"} =
               Slack.Helpers.parse_message_type_params(~S(\\ note))

      assert %{"private" => true, "type" => "note"} =
               Slack.Helpers.parse_message_type_params(";; note")

      assert %{"private" => true, "type" => "note"} =
               Slack.Helpers.parse_message_type_params(~S(\\note))

      assert %{"private" => true, "type" => "note"} =
               Slack.Helpers.parse_message_type_params(";;note")
    end

    test "Helpers.find_slack_user_mentions/1 extracts @mentions in a Slack message" do
      assert ["<@UABC123>"] =
               Slack.Helpers.find_slack_user_mentions("Hi <@UABC123>! How can we help you?")

      assert ["<@UABC123>", "<@UDEF234>"] =
               Slack.Helpers.find_slack_user_mentions(
                 "Hi <@UABC123>! Did you talk to <@UDEF234>?"
               )

      # All these should have no matches
      [
        "Hi there!",
        "<this is not a link or user ID>",
        "@papercups is awesome",
        "Yo | yo | yo",
        "<links-must-start-with-http.com>",
        "<#C123> is a link to a channel"
      ]
      |> Enum.each(fn text ->
        assert [] = Slack.Helpers.find_slack_user_mentions(text)
      end)
    end

    test "Helpers.find_slack_links/1 extracts links in a Slack message" do
      assert ["<http://papercups.io|www.papercups.io>"] =
               Slack.Helpers.find_slack_links(
                 "Check out our website: <http://papercups.io|www.papercups.io>"
               )

      assert [
               "<https://papercups.io>",
               "<http://papercups.io|papercups.io>",
               "<http://papercups.io|www.papercups.io>"
             ] =
               Slack.Helpers.find_slack_links("""
               Check out my favorite links:
               - <https://papercups.io> and
               - <http://papercups.io|papercups.io> and
               - <http://papercups.io|www.papercups.io>
               """)

      # All these should have no matches
      [
        "Hi there!",
        "<this is not a link or user ID>",
        "@papercups is awesome",
        "Yo | yo | yo",
        "<links-must-start-with-http.com>",
        "<#C123> is a link to a channel"
      ]
      |> Enum.each(fn text ->
        assert [] = Slack.Helpers.find_slack_links(text)
      end)
    end

    test "Helpers.find_slack_mailto_links/1 extracts mailto links in a Slack message" do
      assert ["<mailto:alex@test.com|alex@test.com>"] =
               Slack.Helpers.find_slack_mailto_links(
                 "Email me at <mailto:alex@test.com|alex@test.com>"
               )

      assert [
               "<mailto:alex@test.com|alex@test.com>",
               "<mailto:alex@test.com|test@alex.com>"
             ] =
               Slack.Helpers.find_slack_mailto_links(
                 "Email me at <mailto:alex@test.com|alex@test.com> or <mailto:alex@test.com|test@alex.com>"
               )

      # All these should have no matches
      [
        "Hi there!",
        "<this is not a link or user ID>",
        "@papercups is awesome",
        "Yo | yo | yo",
        "<links-must-start-with-http.com>",
        "<#C123> is a link to a channel"
      ]
      |> Enum.each(fn text ->
        assert [] = Slack.Helpers.find_slack_mailto_links(text)
      end)
    end

    test "Helpers.get_slack_message_metadata/1 extracts mentions/links metadata in a Slack message" do
      assert %{
               mentions: ["<@UABC123>"]
             } = Slack.Helpers.get_slack_message_metadata("Hi there <@UABC123>!")

      assert %{
               mentions: ["<@UABC123>"],
               links: ["<https://papercups.io|papercups.io>"]
             } =
               Slack.Helpers.get_slack_message_metadata(
                 "Hi there <@UABC123>! Check out our website <https://papercups.io|papercups.io>"
               )

      assert %{
               links: ["<https://papercups.io|papercups.io>"],
               mailto_links: ["<mailto:alex@papercups.io|alex@papercups.io>"],
               mentions: ["<@UABC123>"]
             } =
               Slack.Helpers.get_slack_message_metadata(
                 "Hi there <@UABC123>! Check out our website <https://papercups.io|papercups.io> or email us at <mailto:alex@papercups.io|alex@papercups.io>"
               )

      # All these should have no metadata
      [
        "Hi there!",
        "<this is not a link or user ID>",
        "@papercups is awesome",
        "Yo | yo | yo",
        "<links-must-start-with-http.com>",
        "<#C123> is a link to a channel"
      ]
      |> Enum.each(fn text ->
        refute Slack.Helpers.get_slack_message_metadata(text)
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

    test "Helpers.get_slack_conversation_status/1 gets the status of a conversation for Slack" do
      unhandled = build(:conversation, status: "open")
      in_progress = build(:conversation, status: "open", first_replied_at: DateTime.utc_now())
      closed_v1 = build(:conversation, status: "closed")
      closed_v2 = build(:conversation, closed_at: DateTime.utc_now())

      assert ":wave: Unhandled" = Slack.Helpers.get_slack_conversation_status(unhandled)

      assert ":speech_balloon: In progress" =
               Slack.Helpers.get_slack_conversation_status(in_progress)

      assert ":white_check_mark: Closed" = Slack.Helpers.get_slack_conversation_status(closed_v1)
      assert ":white_check_mark: Closed" = Slack.Helpers.get_slack_conversation_status(closed_v2)
    end

    test "Helpers.is_slack_conversation_status_field?/1 checks if a Slack message field is the 'Status' field" do
      assert Slack.Helpers.is_slack_conversation_status_field?(%{"text" => "*Status:*\nUnhandled"})

      assert Slack.Helpers.is_slack_conversation_status_field?(%{
               "text" => "*Conversation status:*\nIn progress"
             })

      assert Slack.Helpers.is_slack_conversation_status_field?(%{
               "text" => "*Conversation Status:*\nClosed"
             })

      refute Slack.Helpers.is_slack_conversation_status_field?(%{"text" => "*Name:*\nAlex"})
      refute Slack.Helpers.is_slack_conversation_status_field?(%{"text" => "*Browser:*\nChrome"})

      refute Slack.Helpers.is_slack_conversation_status_field?(%{
               "unknown" => "*Status:*\nUnhandled"
             })

      refute Slack.Helpers.is_slack_conversation_status_field?(%{})
    end

    test "Helpers.update_fields_with_conversation_status/2 updates Slack message block fields with status" do
      unhandled_conversation = build(:conversation, status: "open")

      in_progress_conversation =
        build(:conversation, status: "open", first_replied_at: DateTime.utc_now())

      closed_conversation = build(:conversation, status: "closed")

      fields = [
        %{
          "text" => "*Name:*\nAnonymous User"
        },
        %{
          "text" => "*URL:*\nwww.papercups.io"
        },
        %{
          "text" => "*Timezone:*\nNew York"
        }
      ]

      latest_fields =
        Slack.Helpers.update_fields_with_conversation_status(
          fields,
          unhandled_conversation
        )

      assert [
               %{"text" => "*Name:*\nAnonymous User"},
               %{"text" => "*URL:*\nwww.papercups.io"},
               %{"text" => "*Timezone:*\nNew York"},
               %{"text" => "*Status:*\n:wave: Unhandled"}
             ] = latest_fields

      latest_fields =
        Slack.Helpers.update_fields_with_conversation_status(
          fields,
          in_progress_conversation
        )

      assert [
               %{"text" => "*Name:*\nAnonymous User"},
               %{"text" => "*URL:*\nwww.papercups.io"},
               %{"text" => "*Timezone:*\nNew York"},
               %{"text" => "*Status:*\n:speech_balloon: In progress"}
             ] = latest_fields

      latest_fields =
        Slack.Helpers.update_fields_with_conversation_status(
          fields,
          closed_conversation
        )

      assert [
               %{"text" => "*Name:*\nAnonymous User"},
               %{"text" => "*URL:*\nwww.papercups.io"},
               %{"text" => "*Timezone:*\nNew York"},
               %{"text" => "*Status:*\n:white_check_mark: Closed"}
             ] = latest_fields
    end
  end
end
