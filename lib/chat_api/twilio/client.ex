defmodule ChatApi.Twilio.Client do
  @moduledoc """
  A module for interacting with the Twilio API.
  """

  require Logger

  @spec client(map() | map()) :: Tesla.Client.t()
  def client(%{auth_token: token, account_sid: account_sid}) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.twilio.com/2010-04-01"},
      {Tesla.Middleware.Headers,
       [{"Authorization", Plug.BasicAuth.encode_basic_auth(account_sid, token)}]},
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  @spec send_message(map(), map()) :: Tesla.Env.result()
  def send_message(params, %{account_sid: account_sid} = authorization) do
    message = Map.new(params, fn {k, v} -> {k |> to_string() |> Macro.camelize(), v} end)

    authorization
    |> client()
    |> Tesla.post("/Accounts/#{account_sid}/Messages.json", message)
  end
end
