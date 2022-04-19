use Mix.Config

config :chat_api,
  environment: Mix.env(),
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

# Set up timezone database
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

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

config :pow, Pow.Postgres.Store,
  repo: ChatApi.Repo,
  schema: ChatApi.Auth.PowSession

config :joken,
  rs256: [
    signer_alg: "RS256",
    key_pem: System.get_env("PAPERCUPS_GITHUB_PEM")
  ]

config :chat_api, :pow,
  user: ChatApi.Users.User,
  repo: ChatApi.Repo,
  cache_store_backend: Pow.Postgres.Store

config :chat_api, Oban,
  repo: ChatApi.Repo,
  plugins: [{Oban.Plugins.Pruner, limit: 1000, max_age: 300}],
  queues: [default: 10, events: 50, mailers: 20],
  crontab: [
    # Hourly example worker
    {"0 * * * *", ChatApi.Workers.Example},
    {"0 * * * *", ChatApi.Workers.ArchiveStaleClosedConversations},
    # Syncs every minute
    {"* * * * *", ChatApi.Workers.SyncGmailInboxes},
    # Check for reminders every 30 mins
    {"*/30 * * * *", ChatApi.Workers.SendAllConversationReminders},
    # Sends everyday at 2pm UTC/9am EST
    {"0 14 * * *", ChatApi.Workers.SendPgNewsletter}
    # TODO: uncomment this after testing manually
    # {"0 * * * *", ChatApi.Workers.ArchiveStaleFreeTierConversations}
  ]

config :chat_api, ChatApi.Mailers.Gmail, adapter: Swoosh.Adapters.Gmail

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
