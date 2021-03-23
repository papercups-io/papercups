defmodule ChatApiWeb.TwilioController do
  use ChatApiWeb, :controller

  alias ChatApi.Twilio
  alias ChatApi.Twilio.TwilioAuthorization

  require Logger

  action_fallback(ChatApiWeb.FallbackController)

  @spec auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def auth(conn, %{"authorization" => authorization}) do
    Logger.info("Params from Twilio auth: #{inspect(authorization)}")

    # TODO: verify that auth info works with Twilio API before creating?
    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         params <- Map.merge(authorization, %{"account_id" => account_id, "user_id" => user_id}),
         {:ok, result} <- Twilio.create_or_update_authorization!(params) do
      json(conn, %{data: %{ok: true, id: result.id}})
    else
      _ -> json(conn, %{data: %{ok: false}})
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
  def webhook(conn, payload) do
    Logger.debug("Payload from Twilio webhook: #{inspect(payload)}")
    # TODO: implement me!
    send_resp(conn, 200, "")
  end
end
