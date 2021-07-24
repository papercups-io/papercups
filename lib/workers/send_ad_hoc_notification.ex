defmodule ChatApi.Workers.SendAdHocNotification do
  @moduledoc false

  use Oban.Worker, queue: :mailers
  import Ecto.Query, warn: false
  require Logger

  alias ChatApi.{
    Accounts,
    Conversations,
    Customers,
    Messages,
    Repo
  }

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{args: %{"text" => text, "account_id" => account_id}}) do
    IO.inspect(%{"text" => text, "account_id" => account_id},
      label: "ChatApi.Workers.SendAdHocNotification"
    )

    notify(text, account_id)

    :ok
  end

  def notify(text, account_id) do
    with %{company_name: company_name} <- Accounts.get_account!(account_id),
         # TODO: use founders@
         {:ok, customer} <-
           Customers.find_or_create_by_email("alex@papercups.io", account_id, %{
             name: "Papercups Team",
             profile_photo_url:
               "https://avatars.slack-edge.com/2021-01-13/1619416452487_002cddd7d8aea1950018_192.png"
           }),
         :ok <- should_send_message(text, account_id: account_id, customer_id: customer.id),
         :ok <- Logger.info("Sending to #{company_name}: #{text}"),
         # TODO: should we just create a new conversation for each message?
         {:ok, conversation} <-
           Conversations.find_or_create_by_customer(account_id, customer.id, %{"source" => "chat"}),
         {:ok, message} <-
           Messages.create_message(%{
             source: "api",
             account_id: account_id,
             conversation_id: conversation.id,
             customer_id: customer.id,
             body: text
           }) do
      message.id
      |> Messages.get_message!()
      |> Messages.Notification.broadcast_to_customer!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:mattermost)
      |> Messages.Notification.notify(:webhooks)
      |> Messages.Notification.notify(:gmail)
      |> Messages.Notification.notify(:sms)
    else
      error ->
        Logger.info(
          "Skipped sending #{inspect(text)} to account #{inspect(account_id)}: #{inspect(error)}"
        )
    end
  end

  defp should_send_message(text, account_id: account_id, customer_id: customer_id) do
    query =
      from(m in Message,
        join: c in Conversation,
        on: m.conversation_id == c.id,
        where:
          m.account_id == ^account_id and
            m.customer_id == ^customer_id and
            m.body == ^text and
            is_nil(c.archived_at),
        select: count("*")
      )

    if Repo.one(query) > 0 do
      {:error, :message_already_sent}
    else
      :ok
    end
  end
end
