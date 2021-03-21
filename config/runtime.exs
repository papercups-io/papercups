import Config

IO.inspect("runtime.exs")

database_url = System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/chat_api"

require_db_ssl =
  case System.get_env("REQUIRE_DB_SSL") do
    "true" -> true
    "false" -> false
    _ -> true
  end

socket_options =
  case System.get_env("USE_IP_V6") do
    "true" -> [:inet6]
    "false" -> [:inet]
    _ -> [:inet]
  end

config :chat_api, ChatApi.Repo,
  ssl: false,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  socket_options: socket_options

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    "dvPPvOjpgX2Wk8Y3ONrqWsgM9ZtU4sSrs4l/5CFD1sLm4H+CjLU+EidjNGuSz7bz"

config :chat_api, ChatApiWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    compress: true,
    transport_options: [socket_opts: [:inet6]]
  ],
  url: [scheme: "https", host: {:system, "BACKEND_URL"}, port: 443],
  # FIXME: not sure the best way to handle this, but we want
  # to allow our customers' websites to connect to our server
  check_origin: false,
  # force_ssl: [rewrite_on: [:x_forwarded_proto]],
  secret_key_base: secret_key_base

# Do not print debug messages in production
config :logger, level: :info
