defmodule ChatApiWeb.SesController do
  use ChatApiWeb, :controller
  require Logger
  alias ChatApi.{Aws, Conversations, Customers, Messages}
  alias ChatApi.Customers.Customer

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(
        conn,
        %{
          "messageId" => ses_message_id,
          "fromAddress" => [from_address],
          "toAddresses" => to_addresses
        } = _payload
      ) do
    IO.inspect(
      %{
        ses_message_id: ses_message_id,
        from_address: from_address,
        to_addresses: to_addresses
      },
      label: "Payload from SES webhook"
    )

    # TODO: move to worker
    with %{account_id: account_id} <- find_matching_account(to_addresses),
         {:ok, email} <- Aws.retrieve_formatted_email(ses_message_id) do
      IO.inspect(email, label: "Formatted email")

      {:ok, %Customer{} = customer} = Customers.find_or_create_by_email(from_address, account_id)

      IO.inspect(customer, label: "Customer")

      {:ok, conversation} =
        Conversations.create_conversation(%{
          account_id: account_id,
          customer_id: customer.id,
          subject: email.subject,
          # TODO: distinguish between gmail and SES?
          source: "email"
        })

      conversation
      |> Conversations.Notification.broadcast_new_conversation_to_admin!()
      |> Conversations.Notification.notify(:webhooks, event: "conversation:created")

      IO.inspect(conversation, label: "Created conversation!")

      {:ok, message} =
        Messages.create_message(%{
          body: email.formatted_text,
          account_id: account_id,
          conversation_id: conversation.id,
          customer_id: customer.id,
          # TODO: distinguish between gmail and SES?
          source: "email",
          metadata: Aws.format_message_metadata(email),
          sent_at: DateTime.utc_now()
        })

      IO.inspect(message, label: "Created message!")

      message.id
      |> Messages.get_message!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:webhooks)
      |> Messages.Notification.notify(:push)
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:mattermost)
      # NB: for email threads, for now we want to reopen the conversation if it was closed
      |> Messages.Helpers.handle_post_creation_hooks()

      send_resp(conn, 200, "")
    else
      _ -> send_resp(conn, 200, "")
    end
  end

  # NB: just hardcoding account IDs for testing
  defp find_matching_account(email_addresses) do
    if Enum.any?(email_addresses, &String.contains?(&1, "@chat.papercups.io")) do
      %{account_id: "2ebbad4c-b162-4ed2-aff5-eaf9ebf469a5"}
    else
      nil
    end
  end
end
