import Config

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

pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

if config_env() === :prod do
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
    ssl: require_db_ssl,
    url: database_url,
    show_sensitive_data_on_connection_error: false,
    socket_options: socket_options,
    pool_size: pool_size

  ssl_key_path = System.get_env("SSL_KEY_PATH")
  ssl_cert_path = System.get_env("SSL_CERT_PATH")
  https = (ssl_cert_path && ssl_key_path) != nil
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :chat_api, ChatApiWeb.Endpoint,
    http: [
      port: port,
      compress: true,
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: backend_url],
    pubsub_server: ChatApi.PubSub,
    secret_key_base: secret_key_base,
    server: true,
    check_origin: false

  if https do
    config :chat_api, ChatApiWeb.Endpoint,
      https: [
        port: 443,
        cipher_suite: :strong,
        otp_app: :chat_api,
        keyfile: ssl_key_path,
        certfile: ssl_cert_path
      ],
      force_ssl: [rewrite_on: [:x_forwarded_proto]]
  end
end

# Optional
sentry_dsn = System.get_env("SENTRY_DSN")
mailer_adapter = System.get_env("MAILER_ADAPTER", "Swoosh.Adapters.Local")

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

case mailer_adapter do
  "Swoosh.Adapters.Mailgun" ->
    config :chat_api, ChatApi.Mailers,
      adapter: Swoosh.Adapters.Mailgun,
      api_key: System.get_env("MAILGUN_API_KEY"),
      # Domain is the email address that mailgun is sent from
      domain: System.get_env("DOMAIN")

  "Swoosh.Adapters.SMTP" ->
    config :chat_api, ChatApi.Mailers,
      adapter: Swoosh.Adapters.SMTP,
      relay: System.get_env("SMTP_HOST_ADDR", "mail"),
      port: System.get_env("SMTP_HOST_PORT", "25"),
      username: System.get_env("SMTP_USER_NAME"),
      password: System.get_env("SMTP_USER_PWD"),
      ssl: System.get_env("SMTP_HOST_SSL_ENABLED") || false,
      tls: :if_available,
      retries: System.get_env("SMTP_RETRIES") || 2,
      no_mx_lookups: System.get_env("SMTP_MX_LOOKUPS_ENABLED") || true

  "Swoosh.Adapters.Local" ->
    config :swoosh,
      serve_mailbox: System.get_env("LOCAL_SERVE_MAILBOX", "false") == "true",
      preview_port: System.get_env("LOCAL_MAILBOX_PREVIEW_PORT", "1234") |> String.to_integer()

    config :chat_api, ChatApi.Mailers, adapter: Swoosh.Adapters.Local

  _ ->
    raise "Unknown mailer_adapter; expected Swoosh.Adapters.Mailgun or Swoosh.Adapters.SMTP"
end

site_id = System.get_env("CUSTOMER_IO_SITE_ID")
customerio_api_key = System.get_env("CUSTOMER_IO_API_KEY")

config :customerio,
  site_id: site_id,
  api_key: customerio_api_key

aws_key_id = System.get_env("AWS_ACCESS_KEY_ID")
aws_secret_key = System.get_env("AWS_SECRET_ACCESS_KEY")
bucket_name = System.get_env("BUCKET_NAME", "papercups-files")
region = System.get_env("AWS_REGION")
function_bucket_name = System.get_env("FUNCTION_BUCKET_NAME", "")
function_role = System.get_env("FUNCTION_ROLE", "")
aws_account_id = System.get_env("AWS_ACCOUNT_ID", "")

config :chat_api,
  bucket_name: bucket_name,
  region: region,
  function_bucket_name: function_bucket_name,
  aws_account_id: aws_account_id,
  function_role: function_role

config :ex_aws,
  access_key_id: aws_key_id,
  secret_access_key: aws_secret_key,
  region: region,
  s3: [
    scheme: "https://",
    region: region
  ]

if System.get_env("APPSIGNAL_API_KEY") do
  config :appsignal, :config,
    otp_app: :chat_api,
    name: "chat_api",
    push_api_key: System.get_env("APPSIGNAL_API_KEY"),
    env: Mix.env(),
    active: true
end

case System.get_env("PAPERCUPS_STRIPE_SECRET") do
  "sk_" <> _rest = api_key ->
    config :stripity_stripe, api_key: api_key

  _ ->
    nil
end
