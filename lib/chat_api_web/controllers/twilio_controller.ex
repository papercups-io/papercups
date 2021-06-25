defmodule ChatApiWeb.TwilioController do
  use ChatApiWeb, :controller

  alias ChatApi.{Conversations, Customers, Messages, Twilio}
  alias ChatApi.Twilio.TwilioAuthorization

  require Logger

  action_fallback(ChatApiWeb.FallbackController)

  @spec send(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send(conn, %{"to" => to, "body" => body}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         %TwilioAuthorization{from_phone_number: from_phone_number} = auth <-
           Twilio.get_authorization_by_account(account_id),
         {:ok, %{body: json}} <-
           Twilio.Client.send_message(%{To: to, From: from_phone_number, Body: body}, auth),
         {:ok, data} <- Jason.decode(json) do
      json(conn, %{data: data})
    else
      _ -> json(conn, %{data: nil})
    end
  end

  @spec auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def auth(conn, %{"authorization" => authorization}) do
    Logger.info("Params from Twilio auth: #{inspect(authorization)}")

    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         params <- Map.merge(authorization, %{"account_id" => account_id, "user_id" => user_id}),
         :ok <- verify_authorization(params),
         {:ok, result} <- Twilio.create_or_update_authorization!(params) do
      json(conn, %{data: %{ok: true, id: result.id}})
    else
      {:error, :invalid_twilio_authorization, _} ->
        json(conn, %{data: %{ok: false, error: "Invalid Twilio authorization details."}})

      _error ->
        json(conn, %{data: %{ok: false}})
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    authorization =
      conn
      |> Pow.Plug.current_user()
      |> Map.get(:account_id)
      |> Twilio.get_authorization_by_account()

    case authorization do
      nil ->
        json(conn, %{data: nil})

      auth ->
        json(conn, %{
          data: %{
            id: auth.id,
            created_at: auth.inserted_at,
            from_phone_number: auth.from_phone_number
          }
        })
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %TwilioAuthorization{} = auth <-
           Twilio.get_twilio_authorization!(id),
         {:ok, %TwilioAuthorization{}} <- Twilio.delete_twilio_authorization(auth) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(
        conn,
        %{"AccountSid" => account_sid, "To" => to, "From" => from, "Body" => body} = payload
      ) do
    Logger.info("Payload from Twilio webhook: #{inspect(payload)}")

    with %TwilioAuthorization{account_id: account_id} <-
           Twilio.find_twilio_authorization(%{
             twilio_account_sid: account_sid,
             from_phone_number: to
           }),
         {:ok, customer} <- Customers.find_or_create_by_phone(from, account_id),
         {:ok, conversation} <-
           Conversations.find_or_create_by_customer(account_id, customer.id, %{"source" => "sms"}) do
      %{
        body: body,
        account_id: account_id,
        customer_id: customer.id,
        conversation_id: conversation.id,
        source: "sms"
      }
      |> Messages.create_and_fetch!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:webhooks)
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:mattermost)
      |> Messages.Helpers.handle_post_creation_hooks()

      send_resp(conn, 200, "")
    else
      nil ->
        Logger.warn("Twilio account not found")
        send_resp(conn, 200, "")

      error ->
        Logger.error(inspect(error))
        send_resp(conn, 500, "")
    end
  end

  @spec verify_authorization(map()) :: :ok | {:error, atom(), any()}
  defp verify_authorization(
         %{
           "twilio_auth_token" => twilio_auth_token,
           "twilio_account_sid" => twilio_account_sid
         } = params
       )
       when not is_nil(twilio_auth_token) and not is_nil(twilio_account_sid) do
    authorization = %TwilioAuthorization{
      twilio_auth_token: twilio_auth_token,
      twilio_account_sid: twilio_account_sid,
      from_phone_number: params["from_phone_number"],
      account_id: params["account_id"],
      user_id: params["user_id"]
    }

    case Twilio.Client.list_messages(authorization) do
      {:ok, %{status: 200}} -> :ok
      error -> {:error, :invalid_twilio_authorization, error}
    end
  end

  defp verify_authorization(_params),
    do: {:error, :invalid_twilio_authorization, "Missing required params."}
end
