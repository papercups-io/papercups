defmodule ChatApiWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :chat_api

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_chat_api_key",
    signing_salt: "QvEKzv2I"
  ]

  socket("/socket", ChatApiWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false
  )

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :chat_api

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :chat_api)
  end

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Sentry.PlugContext)

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)

  plug(Corsica,
    # FIXME: what's the best way to handle this if we want other websites to
    # be allowed to hit our API?
    origins: "*",
    # origins: [
    #   "http://localhost:3000",
    #   "http://localhost:4000",
    #   "https://taro-chat-v1.herokuapp.com",
    #   ~r{^https?://(.*.?)papercups.io$}
    # ],
    allow_credentials: true,
    allow_headers: ["Content-Type", "Authorization"],
    log: [rejected: :error, invalid: :warn, accepted: :debug]
  )

  plug(ChatApiWeb.Router)
end
