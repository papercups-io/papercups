defmodule ChatApiWeb.Router do
  use ChatApiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug(ChatApiWeb.IPAddressPlug)
    plug(:accepts, ["json"])
    plug(ChatApiWeb.APIAuthPlug, otp_app: :chat_api)
  end

  pipeline :api_protected do
    plug(Pow.Plug.RequireAuthenticated, error_handler: ChatApiWeb.APIAuthErrorHandler)
    plug(ChatApiWeb.EnsureUserEnabledPlug)
  end

  # Swagger
  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :chat_api, swagger_file: "swagger.json"
  end

  # Public routes
  scope "/api", ChatApiWeb do
    pipe_through(:api)

    resources("/registration", RegistrationController, singleton: true, only: [:create])
    resources("/session", SessionController, singleton: true, only: [:create, :delete])
    post("/session/renew", SessionController, :renew)

    # TODO: figure out a way to secure these methods so they aren't abused
    post("/accounts", AccountController, :create)
    post("/conversations", ConversationController, :create)
    post("/customers", CustomerController, :create)
    get("/customers/identify", CustomerController, :identify)
    get("/customers/:id/exists", CustomerController, :exists)
    put("/customers/:id/metadata", CustomerController, :update_metadata)
    get("/widget_settings", WidgetSettingsController, :show)
    put("/widget_settings/metadata", WidgetSettingsController, :update_metadata)
    post("/verify_email", UserController, :verify_email)
    post("/reset_password", UserController, :create_password_reset)
    put("/reset_password", UserController, :reset_password)
    post("/browser_sessions", BrowserSessionController, :create)
    # TODO: figure out how to design these APIs
    post("/browser_sessions/:id/finish", BrowserSessionController, :finish)
    post("/browser_sessions/:id/restart", BrowserSessionController, :restart)
    post("/browser_sessions/:id/identify", BrowserSessionController, :identify)
    get("/browser_sessions/:id/exists", BrowserSessionController, :exists)

    # TODO: figure out a better name?
    get("/conversations/customer", ConversationController, :find_by_customer)

    post("/slack/webhook", SlackController, :webhook)
  end

  # Protected routes
  scope "/api", ChatApiWeb do
    pipe_through([:api, :api_protected])

    get("/me", SessionController, :me)
    get("/accounts/me", AccountController, :me)
    get("/messages/count", MessageController, :count)
    get("/billing", BillingController, :show)
    post("/billing", BillingController, :create)
    put("/billing", BillingController, :update)
    get("/reporting", ReportingController, :index)

    get("/slack/oauth", SlackController, :oauth)
    get("/slack/authorization", SlackController, :authorization)
    get("/gmail/auth", GmailController, :auth)
    get("/gmail/oauth", GmailController, :callback)
    get("/gmail/authorization", GmailController, :authorization)
    post("/gmail/send", GmailController, :send)
    put("/widget_settings", WidgetSettingsController, :update)
    get("/profile", UserProfileController, :show)
    put("/profile", UserProfileController, :update)
    get("/user_settings", UserSettingsController, :show)
    put("/user_settings", UserSettingsController, :update)
    post("/users/:id/disable", UserController, :disable)
    post("/users/:id/enable", UserController, :enable)
    post("/payment_methods", PaymentMethodController, :create)
    get("/payment_methods", PaymentMethodController, :show)
    get("/browser_sessions/count", BrowserSessionController, :count)

    resources("/user_invitations", UserInvitationController, except: [:new, :edit])
    resources("/accounts", AccountController, only: [:update, :delete])
    resources("/messages", MessageController, except: [:new, :edit])
    resources("/conversations", ConversationController, except: [:new, :edit, :create])
    resources("/customers", CustomerController, except: [:new, :edit, :create])
    resources("/event_subscriptions", EventSubscriptionController, except: [:new, :edit])
    resources("/tags", TagController, except: [:new, :edit])
    resources("/browser_sessions", BrowserSessionController, except: [:create, :new, :edit])

    post("/conversations/:conversation_id/tags", ConversationController, :add_tag)
    delete("/conversations/:conversation_id/tags/:tag_id", ConversationController, :remove_tag)
    post("/customers/:customer_id/tags", CustomerController, :add_tag)
    delete("/customers/:customer_id/tags/:tag_id", CustomerController, :remove_tag)
    post("/event_subscriptions/verify", EventSubscriptionController, :verify)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through([:fetch_session, :protect_from_forgery])
      live_dashboard("/dashboard", metrics: ChatApiWeb.Telemetry)
    end
  end

  scope "/", ChatApiWeb do
    pipe_through :browser

    get "/", PageController, :index
    # TODO: move somewhere else?
    get "/gmail/auth", GmailController, :index

    # Fallback to index, which renders React app
    get "/*path", PageController, :index
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Papercups API"
      }
    }
  end
end
