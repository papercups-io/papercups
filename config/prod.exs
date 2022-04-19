use Mix.Config

database_url = System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/chat_api_dev"
pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

require_db_ssl =
  case System.get_env("REQUIRE_DB_SSL") do
    "true" -> true
    "false" -> false
    _ -> true
  end

# Do not print debug messages in production
config :logger, level: :info

# Heroku needs ssl to be set to true and it doesn't run
config :chat_api, ChatApi.Repo,
  ssl: require_db_ssl,
  url: database_url,
  show_sensitive_data_on_connection_error: true,
  socket_options: [:inet],
  pool_size: pool_size

config :chat_api, ChatApiWeb.Endpoint, force_ssl: [rewrite_on: [:x_forwarded_proto], host: nil]
