defmodule ChatApi.Repo do
  use Ecto.Repo,
    otp_app: :chat_api,
    adapter: Ecto.Adapters.Postgres
end
