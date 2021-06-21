use Mix.Config

config :appsignal, :config,
  otp_app: :chat_api,
  name: "chat_api",
  push_api_key: System.get_env("APPSIGNAL_API_KEY"),
  env: Mix.env()
