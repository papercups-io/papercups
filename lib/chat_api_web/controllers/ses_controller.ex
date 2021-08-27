defmodule ChatApiWeb.SesController do
  use ChatApiWeb, :controller
  require Logger
  alias ChatApi.{Aws, Customers}
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

    with %{account_id: account_id} <- find_matching_account(to_addresses),
         IO.inspect(account_id, label: "Found matching account"),
         {:ok, %{body: email}} <- Aws.download_email_message(ses_message_id),
         IO.inspect(email, label: "Unparsed email"),
         %Mail.Message{} = parsed <- Mail.Parsers.RFC2822.parse(email),
         IO.inspect(parsed, label: "Parsed email"),
         {:ok, %Customer{} = customer} <-
           Customers.find_or_create_by_email(from_address, account_id) do
      # TODO: check where email is coming from/to
      # TODO: check to_addresses for valid address matching account
      # TODO: use from_address to find/create customer record
      IO.inspect(customer, label: "Customer")

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
