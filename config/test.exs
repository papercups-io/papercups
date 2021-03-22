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
  ssl: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  # increase pool queue timeout_ms since async test
  # in sandbox mode may produces get connection timeout
  queue_target: 500

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :chat_api, ChatApiWeb.Endpoint,
  http: [port: 4002],
  server: false

config :chat_api, Oban, crontab: false, queues: false, plugins: false

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env(),
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

# Print only warnings and errors during test
config :logger, level: :warn
