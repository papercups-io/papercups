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
    put("/customers/:id/metadata", CustomerController, :update_metadata)
    get("/customers/identify", CustomerController, :identify)
    get("/widget_settings", WidgetSettingsController, :show)
    put("/widget_settings/metadata", WidgetSettingsController, :update_metadata)

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

    get("/slack/oauth", SlackController, :oauth)
    get("/slack/authorization", SlackController, :authorization)
    put("/widget_settings", WidgetSettingsController, :create_or_update)
    get("/profile", UserProfileController, :show)
    put("/profile", UserProfileController, :create_or_update)
    get("/user_settings", UserSettingsController, :show)
    put("/user_settings", UserSettingsController, :create_or_update)
    post("/payment_methods", PaymentMethodController, :create)
    get("/payment_methods", PaymentMethodController, :show)

    resources("/user_invitations", UserInvitationController, except: [:new, :edit])
    resources("/accounts", AccountController, only: [:update, :delete])
    resources("/messages", MessageController, except: [:new, :edit])
    resources("/conversations", ConversationController, except: [:new, :edit, :create])
    resources("/customers", CustomerController, except: [:new, :edit, :create])
    resources("/event_subscriptions", EventSubscriptionController, except: [:new, :edit])
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
    get "/*path", PageController, :index
  end
end
