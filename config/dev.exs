use Mix.Config

IO.inspect("RUNNING dev.exs")

database_url = System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/chat_api_dev"

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    "dvPPvOjpgX2Wk8Y3ONrqWsgM9ZtU4sSrs4l/5CFD1sLm4H+CjLU+EidjNGuSz7bz"

# # Configure your database
config :chat_api, ChatApi.Repo,
  url: database_url,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  socket_options: [:inet6]

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :chat_api, ChatApiWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  secret_key_base: secret_key_base,
  watchers: [
    node: [
      "node_modules/react-scripts/bin/react-scripts.js",
      "start",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :chat_api, OpusWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/opus_web/(live|views)/.*(ex)$",
      ~r"lib/opus_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
