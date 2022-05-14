defmodule ChatApi.Mailbox do
  @moduledoc """
  A module to simulate interactions with the API client
  """

  require Logger

  use Tesla

  plug(
    Tesla.Middleware.BaseUrl,
    System.get_env("MAILBOX_API_BASE_URL", "")
  )

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
  ])

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger)

  defmodule Email do
    defstruct subject: "",
              from: nil,
              to: nil,
              cc: nil,
              bcc: nil,
              text_body: nil,
              html_body: nil,
              attachments: [],
              reply_to: nil,
              headers: %{},
              # Custom
              template: nil,
              data: %{},
              # Scheduling
              schedule_in: nil,
              scheduled_at: nil,
              # Idempotency/uniqueness
              idempotent: false,
              idempotency_key: nil,
              idempotency_period: nil
  end

  @spec send_email(binary(), map()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def send_email(token, %Email{} = email) when is_binary(token),
    do:
      send_email(token, %{
        email: Map.from_struct(email),
        credentials: default_credentials(),
        # TODO: make this configurable?
        validate: true
      })

  def send_email(token, %Swoosh.Email{} = email) when is_binary(token),
    do:
      send_email(token, %{
        email:
          email
          |> Map.from_struct()
          |> Map.merge(%{data: email.assigns})
          |> Map.merge(email.private),
        credentials: default_credentials(),
        # TODO: make this configurable?
        validate: true
      })

  def send_email(token, params) when is_binary(token) and is_map(params) do
    post("/send", params,
      headers: [
        {"Authorization", "Bearer " <> token}
      ]
    )
  end

  @spec send_email(map()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def send_email(params) when is_map(params),
    do: send_email(System.get_env("MAILBOX_API_KEY", ""), params)

  defp default_credentials() do
    case System.get_env("MAILER_ADAPTER") do
      "Swoosh.Adapters.Mailgun" ->
        %{
          adapter: "mailgun"
          # NB: avoiding this for now
          # api_key: System.get_env("MAILGUN_API_KEY"),
          # domain: System.get_env("DOMAIN")
        }

      _ ->
        %{adapter: "mailgun"}
    end
  end
end
