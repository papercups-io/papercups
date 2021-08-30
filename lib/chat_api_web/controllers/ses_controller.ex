defmodule ChatApiWeb.SesController do
  use ChatApiWeb, :controller
  require Logger
  alias ChatApi.{Aws, Conversations, Customers, Messages}
  alias ChatApi.Accounts.Account
  alias ChatApi.Conversations.Conversation
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

    # TODO: move to worker?
    case get_message_resource(to_addresses) do
      %Conversation{} = conversation ->
        handle_existing_thread(conversation, %{
          ses_message_id: ses_message_id,
          from_address: from_address
        })

      %Account{} = account ->
        handle_new_thread(account, %{
          ses_message_id: ses_message_id,
          from_address: from_address
        })

      _ ->
        nil
    end

    send_resp(conn, 200, "")
  end

  def handle_new_thread(%Account{id: account_id}, %{
        ses_message_id: ses_message_id,
        from_address: from_address
      }) do
    with {:ok, email} <- Aws.retrieve_formatted_email(ses_message_id),
         IO.inspect(email, label: "Formatted email"),
         {:ok, %Customer{} = customer} <-
           Customers.find_or_create_by_email(from_address, account_id),
         IO.inspect(customer, label: "Customer"),
         {:ok, conversation} <-
           create_and_broadcast_conversation(%{
             account_id: account_id,
             customer_id: customer.id,
             subject: email.subject,
             # TODO: distinguish between gmail and SES?
             source: "email"
           }),
         IO.inspect(conversation, label: "Created conversation!"),
         {:ok, message} <-
           create_and_broadcast_message(%{
             body: email.formatted_text,
             account_id: account_id,
             conversation_id: conversation.id,
             customer_id: customer.id,
             # TODO: distinguish between gmail and SES?
             source: "email",
             metadata: Aws.format_message_metadata(email),
             sent_at: DateTime.utc_now()
           }) do
      IO.inspect(message, label: "Created message!")

      message
    else
      error ->
        IO.inspect(error, label: "Something went wrong")

        error
    end
  end

  def handle_existing_thread(%Conversation{account_id: account_id} = conversation, %{
        ses_message_id: ses_message_id,
        from_address: from_address
      }) do
    with {:ok, email} <- Aws.retrieve_formatted_email(ses_message_id),
         IO.inspect(email, label: "Formatted email"),
         {:ok, %Customer{} = customer} <-
           Customers.find_or_create_by_email(from_address, account_id),
         IO.inspect(customer, label: "Customer"),
         {:ok, message} <-
           create_and_broadcast_message(%{
             body: email.formatted_text,
             account_id: account_id,
             conversation_id: conversation.id,
             customer_id: customer.id,
             # TODO: distinguish between gmail and SES?
             source: "email",
             metadata: Aws.format_message_metadata(email),
             sent_at: DateTime.utc_now()
           }) do
      IO.inspect(message, label: "Created message!")

      message
    else
      error ->
        IO.inspect(error, label: "Something went wrong")

        error
    end
  end

  def create_and_broadcast_conversation(params) do
    case Conversations.create_conversation(params) do
      {:ok, conversation} ->
        conversation
        |> Conversations.Notification.broadcast_new_conversation_to_admin!()
        |> Conversations.Notification.notify(:webhooks, event: "conversation:created")

        {:ok, conversation}

      error ->
        error
    end
  end

  def create_and_broadcast_message(params) do
    case Messages.create_message(params) do
      {:ok, message} ->
        message.id
        |> Messages.get_message!()
        |> Messages.Notification.broadcast_to_admin!()
        |> Messages.Notification.notify(:webhooks)
        |> Messages.Notification.notify(:push)
        |> Messages.Notification.notify(:slack)
        |> Messages.Notification.notify(:mattermost)
        # NB: for email threads, for now we want to reopen the conversation if it was closed
        |> Messages.Helpers.handle_post_creation_hooks()

        {:ok, message}

      error ->
        error
    end
  end

  def find_account_by_address(email) do
    if String.contains?(email, "@chat.papercups.io") do
      ChatApi.Accounts.get_account!("2ebbad4c-b162-4ed2-aff5-eaf9ebf469a5")
    else
      nil
    end
  end

  def is_reply_address?("reply+" <> _), do: true
  def is_reply_address?(_), do: false

  def find_conversation_by_address(email) do
    case String.split(email, "@") do
      [name, _] ->
        case name do
          "reply+" <> conversation_id ->
            ChatApi.Conversations.get_conversation(conversation_id)

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  def get_message_resource(email_addresses) do
    email_addresses
    |> Enum.filter(&String.contains?(&1, "@chat.papercups.io"))
    |> Enum.reduce_while(nil, fn
      email, nil ->
        if is_reply_address?(email) do
          {:cont, find_conversation_by_address(email)}
        else
          {:cont, find_account_by_address(email)}
        end

      _, %Account{} = acc ->
        {:halt, acc}

      _, %Conversation{} = acc ->
        {:halt, acc}
    end)
  end
end
