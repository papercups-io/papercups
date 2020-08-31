use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :chat_api, ChatApi.Repo,
  username: "postgres",
  password: "postgres",
  database: "chat_api_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  port: System.get_env("DATABASE_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :chat_api, ChatApiWeb.Endpoint,
  http: [port: 4002],
  server: false

config :chat_api, Oban, crontab: false, queues: false, plugins: false

# Print only warnings and errors during test
config :logger, level: :warn
