# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :chat_api,
  ecto_repos: [ChatApi.Repo],
  generators: [binary_id: true]

config :chat_api, ChatApi.Repo, migration_timestamps: [type: :utc_datetime_usec]

# Configures the endpoint
config :chat_api, ChatApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "9YWmWz498gUjiMQXLq2PX/GcB5uSlqPmcxKPJ49k0vR+6ytuSydFFyDDD3zwRRWi",
  render_errors: [view: ChatApiWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: ChatApi.PubSub,
  live_view: [signing_salt: "pRVXwt3k"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, adapter: Tesla.Adapter.Hackney

# Configure Swagger
config :phoenix_swagger, json_library: Jason

config :chat_api, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      # phoenix routes will be converted to swagger paths
      router: ChatApiWeb.Router,
      # (optional) endpoint config used to set host, port and https schemes.
      endpoint: ChatApiWeb.Endpoint
    ]
  }

# Configure Sentry
sentry_dsn = System.get_env("SENTRY_DSN")

if sentry_dsn != nil do
  config :sentry,
    dsn: sentry_dsn,
    environment_name: Mix.env(),
    included_environments: [:prod],
    enable_source_code_context: true,
    root_source_code_path: File.cwd!()
end

config :chat_api, :pow,
  user: ChatApi.Users.User,
  repo: ChatApi.Repo

config :chat_api, Oban,
  repo: ChatApi.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10, events: 50, mailers: 20],
  crontab: [
    # Hourly example worker
    {"0 * * * *", ChatApi.Workers.Example}
  ]

# Configure Mailgun
mailgun_api_key = System.get_env("MAILGUN_API_KEY")
domain = System.get_env("DOMAIN")

if mailgun_api_key != nil and domain != nil do
  config :chat_api, ChatApi.Mailer,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: mailgun_api_key,
    domain: domain
end

site_id = System.get_env("CUSTOMER_IO_SITE_ID")
customerio_api_key = System.get_env("CUSTOMER_IO_API_KEY")

if site_id != nil and customerio_api_key != nil do
  config :customerio,
    site_id: site_id,
    api_key: customerio_api_key
end

case System.get_env("PAPERCUPS_STRIPE_SECRET") do
  "sk_" <> _rest = api_key ->
    config :stripity_stripe, api_key: api_key

  _ ->
    nil
end

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
