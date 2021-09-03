defmodule ChatApi.SendSesReplyEmailTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  import Mock

  setup do
    account = insert(:account, company_name: "Test Co")
    user = insert(:user, account: account)
    customer = insert(:customer, account: account)
    conversation = insert(:conversation, account: account, customer: customer, source: "email")

    {:ok, account: account, customer: customer, user: user, conversation: conversation}
  end

  describe "send_email_via_ses/2" do
    test "sends an email if the previous message has SES metadata", %{
      account: account,
      user: user,
      conversation: conversation
    } do
      message =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          customer: nil
        )

      metadata = %{
        "ses_message_id" => "<previous@email.amazonses.com>",
        "ses_references" => "<reference@email.amazonses.com>",
        "ses_subject" => "Test subject line",
        "ses_from" => "test@papercups.io"
      }

      with_mock ChatApi.Aws,
        send_email: fn _ ->
          %{body: %{message_id: "some_message_id"}, status_code: 200}
        end do
        assert {:ok, message} =
                 ChatApi.Workers.SendSesReplyEmail.send_email_via_ses(message, metadata)

        assert %{
                 "ses_from" => "test@papercups.io",
                 "ses_in_reply_to" => "<previous@email.amazonses.com>",
                 "ses_message_id" => "<some_message_id@email.amazonses.com>",
                 "ses_references" =>
                   "<reference@email.amazonses.com> <previous@email.amazonses.com>",
                 "ses_subject" => "Test subject line"
               } = message.metadata

        assert_called(
          ChatApi.Aws.send_email(%{
            from: "Test Co Team <mailer@chat.papercups.io>",
            in_reply_to: "<previous@email.amazonses.com>",
            references: "<reference@email.amazonses.com> <previous@email.amazonses.com>",
            reply_to: "reply+#{conversation.id}@chat.papercups.io",
            subject: "Test subject line",
            text: "some message body",
            to: "test@papercups.io"
          })
        )
      end
    end

    test "handles messages with attachments", %{
      account: account,
      user: user,
      conversation: conversation
    } do
      message =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          customer: nil
        )

      file = insert(:file, account: account, filename: "test.png")

      with_mock ChatApi.Aws,
        send_email: fn _ ->
          %{body: %{message_id: "some_message_id"}, status_code: 200}
        end,
        download_file_url: fn _ ->
          {:ok, %{body: "file_binary", status_code: 200}}
        end do
        assert {:ok, _} = ChatApi.Messages.add_attachment(message, file)

        message = ChatApi.Messages.get_message!(message.id)

        metadata = %{
          "ses_message_id" => "<previous@email.amazonses.com>",
          "ses_references" => "<reference@email.amazonses.com>",
          "ses_subject" => "Test subject line",
          "ses_from" => "test@papercups.io"
        }

        assert {:ok, _} = ChatApi.Workers.SendSesReplyEmail.send_email_via_ses(message, metadata)
        assert_called(ChatApi.Aws.send_email(%{attachments: [{"test.png", "file_binary"}]}))
      end
    end

    test "should only work for messages send by agents (users)", %{
      account: account,
      conversation: conversation,
      customer: customer
    } do
      customer_message =
        insert(:message,
          account: account,
          conversation: conversation,
          customer: customer,
          user: nil
        )

      refute ChatApi.Workers.SendSesReplyEmail.send_email_via_ses(customer_message)
    end

    test "should only work when metadata contains SES info", %{
      account: account,
      conversation: conversation,
      user: user
    } do
      message =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          customer: nil
        )

      metadata = %{"foo" => "bar"}

      refute ChatApi.Workers.SendSesReplyEmail.send_email_via_ses(message, metadata)
    end
  end
end
