defmodule ChatApi.Workers.ProcessSesEvent do
  use Oban.Worker, queue: :default

  require Logger
  alias ChatApi.{Aws, Conversations, Customers, ForwardingAddresses, Messages}
  alias ChatApi.Accounts.Account
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.Message

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(
        %Oban.Job{
          args: %{
            "ses_message_id" => ses_message_id,
            "from_address" => from_address,
            "to_addresses" => to_addresses,
            "forwarded_to" => forwarded_to
          }
        } = job
      ) do
    Logger.info("Processing SES event: #{inspect(job)}")

    case get_message_resource(to_addresses, forwarded_to) do
      %Conversation{} = conversation ->
        IO.inspect(conversation, label: "Found conversation!")

        handle_existing_thread(conversation, %{
          ses_message_id: ses_message_id,
          from_address: from_address
        })

      %Account{} = account ->
        IO.inspect(account, label: "Found account!")

        handle_new_thread(account, %{
          ses_message_id: ses_message_id,
          from_address: from_address
        })

      _ ->
        nil
    end

    :ok
  end

  @spec handle_new_thread(Account.t(), map()) :: {:ok, Message.t()} | {:error, any()}
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
         IO.inspect(conversation, label: "Created conversation!") do
      create_and_broadcast_message(%{
        body: email.formatted_text,
        account_id: account_id,
        conversation_id: conversation.id,
        customer_id: customer.id,
        # TODO: distinguish between gmail and SES?
        source: "email",
        metadata: Aws.format_message_metadata(email),
        sent_at: DateTime.utc_now()
      })
    else
      error ->
        Logger.error("Something went wrong in `handle_new_thread/2`: #{inspect(error)}")

        error
    end
  end

  @spec handle_existing_thread(Conversation.t(), map()) :: {:ok, Message.t()} | {:error, any()}
  def handle_existing_thread(%Conversation{account_id: account_id} = conversation, %{
        ses_message_id: ses_message_id,
        from_address: from_address
      }) do
    with {:ok, email} <- Aws.retrieve_formatted_email(ses_message_id),
         IO.inspect(email, label: "Formatted email"),
         {:ok, %Customer{} = customer} <-
           Customers.find_or_create_by_email(from_address, account_id),
         IO.inspect(customer, label: "Customer") do
      create_and_broadcast_message(%{
        body: email.formatted_text,
        account_id: account_id,
        conversation_id: conversation.id,
        customer_id: customer.id,
        # TODO: distinguish between gmail and SES?
        source: "email",
        metadata: Aws.format_message_metadata(email),
        sent_at: DateTime.utc_now()
      })
    else
      error ->
        Logger.error("Something went wrong in `handle_existing_thread/2`: #{inspect(error)}")

        error
    end
  end

  @spec create_and_broadcast_conversation(map()) :: {:ok, Conversation.t()} | {:error, any()}
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

  @spec create_and_broadcast_message(map()) :: {:ok, Message.t()} | {:error, any()}
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

  @spec find_account_by_address(binary()) :: Account.t() | nil
  def find_account_by_address(email) do
    domain = Application.get_env(:chat_api, :ses_forwarding_domain, "chat.papercups.io")

    if String.contains?(email, domain) do
      ForwardingAddresses.find_account_by_forwarding_address(email)
    else
      nil
    end
  end

  @spec is_reply_address?(binary() | nil) :: boolean()
  def is_reply_address?("reply+" <> _), do: true
  def is_reply_address?(_), do: false

  @spec find_conversation_by_address(binary()) :: Conversation.t() | nil
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

  @spec get_message_resource([binary()], binary() | nil) :: Conversation.t() | Account.t() | nil
  def get_message_resource(email_addresses, nil),
    do: get_message_resource(email_addresses)

  def get_message_resource(email_addresses, forwarded_to_address) do
    # TODO: eventually we may want to verify that the `forwarded_to_address` and
    # the `to_addresses` have a valid match in the `forwarding_addresses` table
    get_message_resource([forwarded_to_address | email_addresses])
  end

  @spec get_message_resource([binary()]) :: Conversation.t() | Account.t() | nil
  def get_message_resource(email_addresses) do
    email_addresses
    |> Enum.reject(&is_nil/1)
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
