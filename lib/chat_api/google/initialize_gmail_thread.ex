defmodule ChatApi.Google.InitializeGmailThread do
  @moduledoc false

  require Logger

  alias ChatApi.{Accounts, Conversations, Google, Messages}
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.Message

  @spec send(binary(), Conversation.t()) :: Message.t() | {:error, String.t()}
  def send(
        text,
        %Conversation{
          id: conversation_id,
          account_id: account_id,
          subject: subject
        }
      ) do
    with {:ok, %{refresh_token: refresh_token, user_id: user_id}} <-
           get_gmail_authorization(account_id),
         {:ok, from} <- get_authorized_gmail_address(refresh_token),
         {:ok, to} <- validate_conversation_customer_email(conversation_id) do
      subject =
        case subject do
          nil -> get_default_subject(account_id)
          str -> str
        end

      %{
        "id" => gmail_message_id,
        "threadId" => gmail_thread_id
      } =
        Google.Gmail.send_message(refresh_token, %{
          to: to,
          from: from,
          subject: subject,
          text: text
        })

      {:ok, _gmail_conversation_thread} =
        Google.create_gmail_conversation_thread(%{
          gmail_thread_id: gmail_thread_id,
          gmail_initial_subject: subject,
          conversation_id: conversation_id,
          account_id: account_id
        })

      gmail_message =
        gmail_message_id
        |> Google.Gmail.get_message(refresh_token)
        |> Google.Gmail.format_thread_message()

      %{
        body: text,
        conversation_id: conversation_id,
        account_id: account_id,
        user_id: user_id,
        source: "email",
        metadata: Google.Gmail.format_message_metadata(gmail_message),
        sent_at:
          with {unix, _} <- Integer.parse(gmail_message.ts),
               {:ok, datetime} <- DateTime.from_unix(unix, :millisecond) do
            datetime
          else
            _ -> DateTime.utc_now()
          end
      }
      |> Messages.create_and_fetch!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:mattermost)
      |> Messages.Notification.notify(:webhooks)
    end
  end

  defp get_gmail_authorization(account_id) do
    # TODO: if a personal authorization exists, use that -- otherwise fall back to the account-level
    # (Will need to pass in a user_id as well to get the personal account)
    case Google.get_authorization_by_account(account_id, %{client: "gmail"}) do
      %Google.GoogleAuthorization{} = auth -> {:ok, auth}
      _ -> {:error, "Missing Gmail integration"}
    end
  end

  defp get_authorized_gmail_address(refresh_token) do
    case Google.Gmail.get_profile(refresh_token) do
      %{"emailAddress" => from} -> {:ok, from}
      _ -> {:error, "Invalid Gmail authorization"}
    end
  end

  defp validate_conversation_customer_email(conversation_id) do
    with %Conversation{customer: %Customer{email: email}} <-
           Conversations.get_conversation!(conversation_id),
         true <- ChatApi.Emails.Helpers.valid_format?(email) do
      {:ok, email}
    else
      _ -> {:error, "Invalid customer email address"}
    end
  end

  defp get_default_subject(account_id) do
    account = Accounts.get_account!(account_id)

    "New message from #{account.company_name}"
  end
end
