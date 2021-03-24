defmodule ChatApi.Twilio.Client do
  @moduledoc """
  A module for interacting with the Twilio API.
  """

  require Logger

  @spec client(map() | map()) :: Tesla.Client.t()
  def client(%{twilio_auth_token: twilio_auth_token, twilio_account_sid: twilio_account_sid}) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.twilio.com/2010-04-01"},
      {Tesla.Middleware.Headers,
       [
         {"Authorization",
          Plug.BasicAuth.encode_basic_auth(twilio_account_sid, twilio_auth_token)}
       ]},
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  @spec send_message(map(), map()) :: Tesla.Env.result()
  def send_message(params, %{twilio_account_sid: twilio_account_sid} = authorization) do
    message = Map.new(params, fn {k, v} -> {k |> to_string() |> Macro.camelize(), v} end)

    authorization
    |> client()
    |> Tesla.post("/Accounts/#{twilio_account_sid}/Messages.json", message)
  end

  @spec list_messages(map(), map()) :: Tesla.Env.result()
  def list_messages(%{twilio_account_sid: twilio_account_sid} = authorization, params \\ %{}) do
    query = Map.new(params, fn {k, v} -> {k |> to_string() |> Macro.camelize(), v} end)

    authorization
    |> client()
    |> Tesla.get("/Accounts/#{twilio_account_sid}/Messages.json", query: query)
  end
end
