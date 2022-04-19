defmodule ChatApi.ProcessSesEventText do
  use ChatApi.DataCase

  import ChatApi.Factory
  import Mock

  setup do
    account = insert(:account, company_name: "Test Co")
    user = insert(:user, account: account)
    customer = insert(:customer, account: account, email: "test@customer.co")
    conversation = insert(:conversation, account: account, customer: customer, source: "email")

    {:ok, account: account, customer: customer, user: user, conversation: conversation}
  end

  describe "process_event/1" do
    test "handling new threads", %{account: account} do
      insert(:forwarding_address,
        account: account,
        forwarding_email_address: "company@chat.papercups.io"
      )

      text = "Hello world"

      headers = %{
        "message-id" => "message-id",
        "subject" => "Test subject",
        "from" => "customer@example.co",
        "to" => "support@me.com",
        "cc" => [],
        "bcc" => [],
        "in-reply-to" => "<some-reference-id>",
        "references" => "<another-reference-id>"
      }

      with_mock ChatApi.Aws,
        format_message_metadata: fn _ -> %{} end,
        retrieve_formatted_email: fn _ ->
          {:ok,
           %{
             id: "ses_message_id",
             message_id: headers["message-id"],
             subject: headers["subject"],
             from: headers["from"],
             to: headers["to"],
             cc: headers["cc"],
             bcc: headers["bcc"],
             in_reply_to: headers["in-reply-to"],
             references: headers["references"],
             text: text,
             html: "<p>Hello world</p>",
             formatted_text: text,
             attachments: []
           }}
        end do
        {:ok, message} =
          ChatApi.Workers.ProcessSesEvent.process_event(%{
            ses_message_id: "ses_message_id",
            from_address: "customer@example.co",
            to_addresses: ["support@me.com"],
            forwarded_to: "company@chat.papercups.io",
            received_by: []
          })

        message = ChatApi.Messages.get_message!(message.id)

        assert message.body == text
        assert message.source == "email"
        assert message.conversation.source == "email"
        assert message.conversation.subject == headers["subject"]
        assert message.customer.email == "customer@example.co"
      end
    end

    test "handling existing threads", %{account: account, customer: customer} do
      conversation = insert(:conversation, account: account, customer: customer, source: "email")

      insert(:forwarding_address,
        account: account,
        forwarding_email_address: "company@chat.papercups.io"
      )

      text = "Follow up email"

      headers = %{
        "message-id" => "message-id",
        "subject" => "Test subject",
        "from" => customer.email,
        "to" => "support@me.com",
        "cc" => [],
        "bcc" => [],
        "in-reply-to" => "<some-reference-id>",
        "references" => "<another-reference-id>"
      }

      with_mock ChatApi.Aws,
        format_message_metadata: fn _ -> %{} end,
        retrieve_formatted_email: fn _ ->
          {:ok,
           %{
             id: "ses_message_id",
             message_id: headers["message-id"],
             subject: headers["subject"],
             from: headers["from"],
             to: headers["to"],
             cc: headers["cc"],
             bcc: headers["bcc"],
             in_reply_to: headers["in-reply-to"],
             references: headers["references"],
             text: text,
             html: "<p>Follow up email</p>",
             formatted_text: text,
             attachments: []
           }}
        end do
        {:ok, message} =
          ChatApi.Workers.ProcessSesEvent.process_event(%{
            ses_message_id: "ses_message_id",
            from_address: customer.email,
            to_addresses: ["reply+#{conversation.id}@chat.papercups.io"],
            forwarded_to: nil,
            received_by: []
          })

        message = ChatApi.Messages.get_message!(message.id)

        assert message.conversation_id == conversation.id
        assert message.body == text
        assert message.source == "email"
        assert message.customer_id == customer.id
        assert message.customer.email == customer.email
      end
    end

    test "invalid input", %{customer: customer} do
      ChatApi.Workers.ProcessSesEvent.process_event(%{
        ses_message_id: "ses_message_id",
        from_address: customer.email,
        to_addresses: ["random@chat.papercups.io"],
        forwarded_to: nil,
        received_by: []
      })
    end
  end
end
