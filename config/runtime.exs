import Config
IO.inspect("In runtime.exs")

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

backend_url =
  System.get_env("BACKEND_URL") ||
    raise """
    environment variable BACKEND_URL is missing.
    For example: myselfhostedwebsite.com or papercups.io
    """

# Configure your database
config :chat_api, ChatApi.Repo,
  url: database_url,
  show_sensitive_data_on_connection_error: false,
  pool_size: 10

ssl_key_path = System.get_env("SSL_KEY_PATH")
ssl_cert_path = System.get_env("SSL_CERT_PATH")
https = (ssl_cert_path && ssl_key_path) != nil

if https do
  config :chat_api, ChatApiWeb.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: backend_url],
    pubsub_server: ChatApi.PubSub,
    secret_key_base: secret_key_base,
    https: [
      port: 443,
      cipher_suite: :strong,
      otp_app: :hello,
      keyfile: ssl_key_path,
      certfile: ssl_cert_path
    ],
    server: true,
    check_origin: false
else
  config :chat_api, ChatApiWeb.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: backend_url],
    pubsub_server: ChatApi.PubSub,
    secret_key_base: secret_key_base,
    server: true,
    check_origin: false
end

# Optional
sentry_dsn = System.get_env("SENTRY_DSN")
mailgun_api_key = System.get_env("MAILGUN_API_KEY")

# Configure Sentry
config :sentry,
  dsn: sentry_dsn,
  environment_name: config_env(),
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

config :logger,
  backends: [:console, Sentry.LoggerBackend]

config :logger, Sentry.LoggerBackend,
  # Also send warn messages
  level: :warn,
  # Send messages from Plug/Cowboy
  excluded_domains: [],
  # Send messages like `Logger.error("error")` to Sentry
  capture_log_messages: true

# Domain is the email address that mailgun is sent from
domain = System.get_env("DOMAIN")
# Configure Mailgun
config :chat_api, ChatApi.Mailers.Mailgun,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: mailgun_api_key,
  domain: domain

site_id = System.get_env("CUSTOMER_IO_SITE_ID")
customerio_api_key = System.get_env("CUSTOMER_IO_API_KEY")

config :customerio,
  site_id: site_id,
  api_key: customerio_api_key
