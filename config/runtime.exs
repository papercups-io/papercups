import Config

if config_env() in [:dev, :test] do
  Envy.auto_load()
end

IO.inspect("running RUNTIME.EXS")

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

IO.inspect("database_url")
IO.inspect(database_url)

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    For example: 9YWmWz498gUjiMQXLq2PX/GcB5uSlqPmcxKPJ49k0vR+6ytuSydFFyDDD3zwRRWi
    """

IO.inspect("SECRET_KEY_BASE")
IO.inspect(secret_key_base)

backend_url =
  System.get_env("BACKEND_URL") ||
    raise """
    environment variable BACKEND_URL is missing.
    For example: myselfhostedwebsite.com or papercups.io
    """

IO.inspect("BACKEND_URL")
IO.inspect(backend_url)

# use_ip_v6 = toBool(System.get("USE_IP_V6"), false)
require_db_ssl = String.to_existing_atom(System.get_env("REQUIRE_DB_SSL", "true"))
port = String.to_integer(System.get_env("PORT") || "4000")
use_ip_v6 = String.to_existing_atom(System.get_env("USE_IP_V6", "false"))
IO.inspect("use_ip_v6")
IO.inspect(use_ip_v6)

IO.inspect("require_db_ssl")
IO.inspect(System.get_env("REQUIRE_DB_SSL"))
# IO.inspect(require_db_ssl)

# AWS used for file uploads
aws_key_id = System.get_env("AWS_ACCESS_KEY_ID")
aws_secret_key = System.get_env("AWS_SECRET_ACCESS_KEY")
bucket_name = System.get_env("BUCKET_NAME")
region = System.get_env("AWS_REGION")
pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

IO.inspect("pool_size")
IO.inspect(pool_size)

# For sending default emails
mailgun_api_key = System.get_env("MAILGUN_API_KEY")
domain = System.get_env("DOMAIN")
sentry_dsn = System.get_env("SENTRY_DSN")

if aws_key_id != nil and
     aws_secret_key != nil and
     bucket_name != nil and
     region != nil do
  config :ex_aws,
    access_key_id: aws_key_id,
    secret_access_key: aws_secret_key,
    s3: [
      scheme: "https://",
      host: bucket_name <> ".s3.amazonaws.com",
      region: region
    ]
end

socket_options =
  case use_ip_v6 do
    true -> [:inet6]
    false -> [:inet]
    _ -> [:inet]
  end

# Configure Mailgun
if mailgun_api_key != nil and domain != nil do
  config :chat_api, ChatApi.Mailers.Mailgun,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: mailgun_api_key,
    domain: domain
end

config :chat_api, ChatApi.Repo,
  ssl: require_db_ssl,
  url: database_url,
  pool_size: pool_size,

# # Configure your database
# config :chat_api, ChatApi.Repo,
#   ssl: require_db_ssl,
#   url: database_url,
#   pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

ssl_key_path = System.get_env("SSL_KEY_PATH")
ssl_cert_path = System.get_env("SSL_CERT_PATH")
https = (ssl_cert_path && ssl_key_path) != nil

config :chat_api, ChatApiWeb.Endpoint,
  http: [
    port: port
    # transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

if https do
  config :chat_api, ChatApiWeb.Endpoint,
    url: [host: backend_url],
    pubsub_server: ChatApi.PubSub,
    socket_options: socket_options,
    https: [
      port: 443,
      cipher_suite: :strong,
      otp_app: :hello,
      keyfile: ssl_key_path,
      certfile: ssl_cert_path
    ],
    server: true
end

# else
#   config :chat_api, ChatApiWeb.Endpoint,
#     http: [
#       port: port,
#       transport_options: [socket_opts: [:inet6]]
#     ],
#     url: [scheme: "https", host: {:system, "BACKEND_URL"}, port: 443],
#     # FIXME: not sure the best way to handle this, but we want
#     # to allow our customers' websites to connect to our server
#     check_origin: false,
#     force_ssl: [rewrite_on: [:x_forwarded_proto]]
# end

# config :chat_api, ChatApiWeb.Endpoint,
#   http: [
#     port: String.to_integer(System.get_env("PORT") || "4000"),
#     transport_options: [socket_opts: [:inet6]]
#   ],
#   url: [scheme: "https", host: {:system, "BACKEND_URL"}, port: 443],
#   # FIXME: not sure the best way to handle this, but we want
#   # to allow our customers' websites to connect to our server
#   check_origin: false,
#   force_ssl: [rewrite_on: [:x_forwarded_proto]],
#   secret_key_base: secret_key_base

# end

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

if sentry_dsn != nil do
  config :sentry,
    dsn: sentry_dsn,
    environment_name: Mix.env(),
    included_environments: [:prod],
    enable_source_code_context: true,
    root_source_code_path: File.cwd!()
end
