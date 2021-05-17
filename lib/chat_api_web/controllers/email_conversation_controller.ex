defmodule ChatApiWeb.EmailConversationController do
  use ChatApiWeb, :controller

  alias ChatApi.{Conversations, Messages, Customers}
  alias Customers.{Customer}

  action_fallback(ChatApiWeb.FallbackController)

  @spec create(Conn.t(), map()) :: {:error, Ecto.Changeset.t()} | Plug.Conn.t()
  def create(
        conn,
        %{
          "account_id" => account_id,
          "body" => body,
          "customer_id" => customer_id,
          "email_address" => email_address
        } = params
      ) do
    subject = Map.get(params, "subject")

    with customer <- Customers.get_customer!(customer_id),
         {:ok, %Customer{} = _customer} <-
           Customers.update_customer(customer, %{email: email_address}) do
      create_conversation_and_send_message(conn, %{
        "account_id" => account_id,
        "body" => body,
        "customer_id" => customer_id,
        "email_address" => email_address,
        "subject" => subject
      })
    end
  end

  def create(
        conn,
        %{
          "account_id" => account_id,
          "body" => body,
          "email_address" => email_address
        } = params
      ) do
    subject = Map.get(params, "subject")

    with {:ok, %Customer{} = customer} <-
           Customers.create_customer(
             Customers.get_default_params(%{account_id: account_id, email: email_address})
           ) do
      create_conversation_and_send_message(conn, %{
        "account_id" => account_id,
        "body" => body,
        "customer_id" => customer.id,
        "email_address" => email_address,
        "subject" => subject
      })
    end
  end

  defp create_conversation_and_send_message(conn, %{
         "account_id" => account_id,
         "body" => body,
         "customer_id" => customer_id,
         "email_address" => _email_address,
         "subject" => subject
       }) do
    with {:ok, conversation} <-
           Conversations.create_conversation(%{
             account_id: account_id,
             customer_id: customer_id,
             source: "email"
           }),
         {:ok, _message} <-
           Messages.create_message(%{
             account_id: account_id,
             body: body,
             conversation_id: conversation.id,
             customer_id: customer_id,
             source: "email",
             subject: subject
           }) do
      conversation
      |> Conversations.Notification.broadcast_new_conversation_to_admin!()
      |> Conversations.Notification.notify(:webhooks, event: "conversation:created")

      conn
      |> put_status(:created)
      |> json(%{})
    end
  end
end
