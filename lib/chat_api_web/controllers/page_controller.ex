defmodule ChatApiWeb.PageController do
  use ChatApiWeb, :controller

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    file =
      "./priv/static/index.html"
      |> File.read!()
      |> String.replace(
        "__SERVER_ENV_DATA__",
        Jason.encode!(server_env_data(), escape: :html_safe)
      )

    html(conn, file)
  end

  defp server_env_data() do
    %{
      REACT_APP_SENTRY_DSN: System.get_env("REACT_APP_SENTRY_DSN"),
      REACT_APP_LOGROCKET_ID: System.get_env("REACT_APP_LOGROCKET_ID"),
      REACT_APP_POSTHOG_TOKEN:
        System.get_env("REACT_APP_POSTHOG_TOKEN", "cQo4wipp5ipWWXhTN8kTacBItgqo457yDRtzCMOr-Tw"),
      REACT_APP_POSTHOG_API_HOST:
        System.get_env("REACT_APP_POSTHOG_API_HOST", "https://app.posthog.com"),
      REACT_APP_DEBUG_MODE_ENABLED: System.get_env("REACT_APP_DEBUG_MODE_ENABLED"),
      REACT_APP_EU_EDITION: System.get_env("REACT_APP_EU_EDITION"),
      REACT_APP_URL: System.get_env("REACT_APP_URL", "app.papercups.io"),
      REACT_APP_SLACK_CLIENT_ID:
        System.get_env("REACT_APP_SLACK_CLIENT_ID", "1192316529232.1250363411891"),
      REACT_APP_STRIPE_PUBLIC_KEY: System.get_env("REACT_APP_STRIPE_PUBLIC_KEY"),
      REACT_APP_FILE_UPLOADS_ENABLED: System.get_env("REACT_APP_FILE_UPLOADS_ENABLED"),
      REACT_APP_STORYTIME_ENABLED: System.get_env("REACT_APP_STORYTIME_ENABLED"),
      REACT_APP_ADMIN_ACCOUNT_ID:
        System.get_env("REACT_APP_ADMIN_ACCOUNT_ID", "eb504736-0f20-4978-98ff-1a82ae60b266")
    }
  end
end
