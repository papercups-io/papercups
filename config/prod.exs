use Mix.Config
# Do not print debug messages in production
config :logger, level: :info

# Heroku needs ssl to be set to true and it doesn't run
config :chat_api, ChatApi.Repo,
  show_sensitive_data_on_connection_error: true,
  socket_options: [:inet]
