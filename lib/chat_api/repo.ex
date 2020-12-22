defmodule ChatApi.Repo do
  use Ecto.Repo,
    otp_app: :chat_api,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 50
end
