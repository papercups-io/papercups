import Config

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
    server: true
else
  config :chat_api, ChatApiWeb.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: backend_url],
    pubsub_server: ChatApi.PubSub,
    secret_key_base: secret_key_base,
    server: true
end

# https = (ssl_cert_path && ssl_key_path) != nil
# # ## SSL Support
# #
# # To get SSL working, you will need to add the `https` key
# # to the previous section and set your `:url` port to 443:
# if ssl_key_path && ssl_cert_path do
#   config :chat_api, ChatApiWeb.Endpoint,
#     url: [host: "example.com", port: 443],
#     https: [
#       port: 443,
#       cipher_suite: :strong,
#       keyfile: ssl_key_path,
#       certfile: ssl_cert_path,
#       transport_options: [socket_opts: [:inet6]]
#     ]
# end
