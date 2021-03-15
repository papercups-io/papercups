use Mix.Config
IO.inspect("RUNNING prod.exs")

use Mix.Config

config :chat_api, ChatApiWeb.Endpoint,
  url: [scheme: "https", host: {:system, "BACKEND_URL"}, port: 443],
  # FIXME: not sure the best way to handle this, but we want
  # to allow our customers' websites to connect to our server
  check_origin: false,
  force_ssl: [rewrite_on: [:x_forwarded_proto]]

# Do not print debug messages in production
config :logger, level: :info
