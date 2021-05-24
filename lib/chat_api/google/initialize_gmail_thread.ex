defmodule ChatApi.Google.InitializeGmailThread do
  @moduledoc false

  require Logger

  alias ChatApi.{Accounts, Conversations, Google, Messages}
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer
  alias ChatApi.Google.GoogleAuthorization
  alias ChatApi.Messages.Message

  @spec send(binary(), Conversation.t(), integer()) :: Message.t() | {:error, String.t()}
  def send(
        text,
        %Conversation{
          id: conversation_id,
          account_id: account_id,
          subject: subject
        },
        user_id
      ) do
    with {:ok, %{refresh_token: refresh_token, user_id: _auth_user_id} = authorization} <-
           get_gmail_authorization(account_id, user_id),
         {:ok, from} <- get_authorized_gmail_address(refresh_token),
         {:ok, to} <- validate_conversation_customer_email(conversation_id) do
      sender = Google.format_sender_display_name(authorization, user_id, account_id)

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
          from: {sender, from},
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

  @spec get_gmail_authorization(binary(), integer()) ::
          {:ok, GoogleAuthorization.t()} | {:error, binary()}
  defp get_gmail_authorization(account_id, user_id) do
    case Google.get_support_gmail_authorization(account_id, user_id) do
      %Google.GoogleAuthorization{} = auth -> {:ok, auth}
      _ -> {:error, "Missing Gmail integration"}
    end
  end

  @spec get_authorized_gmail_address(binary()) :: {:ok, binary()} | {:error, binary()}
  defp get_authorized_gmail_address(refresh_token) do
    case Google.Gmail.get_profile(refresh_token) do
      %{"emailAddress" => from} -> {:ok, from}
      _ -> {:error, "Invalid Gmail authorization"}
    end
  end

  @spec validate_conversation_customer_email(binary()) :: {:ok, binary()} | {:error, binary()}
  defp validate_conversation_customer_email(conversation_id) do
    with %Conversation{customer: %Customer{email: email}} <-
           Conversations.get_conversation!(conversation_id),
         true <- ChatApi.Emails.Helpers.valid_format?(email) do
      {:ok, email}
    else
      _ -> {:error, "Invalid customer email address"}
    end
  end

  @spec get_default_subject(binary()) :: binary()
  defp get_default_subject(account_id) do
    account = Accounts.get_account!(account_id)

    "New message from #{account.company_name}"
  end
end
