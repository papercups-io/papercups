defmodule ChatApiWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chat_api,
    pubsub_server: ChatApi.PubSub
end
