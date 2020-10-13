defmodule ChatApiWeb.BrowserSessionController do
  use ChatApiWeb, :controller

  alias ChatApi.BrowserSessions
  alias ChatApi.BrowserSessions.BrowserSession

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      browser_sessions = BrowserSessions.list_browser_sessions(account_id)
      render(conn, "index.json", browser_sessions: browser_sessions)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"browser_session" => browser_session_params}) do
    with {:ok, %BrowserSession{} = browser_session} <-
           BrowserSessions.create_browser_session(browser_session_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.browser_session_path(conn, :show, browser_session))
      |> render("show.json", browser_session: browser_session)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    browser_session = BrowserSessions.get_browser_session!(id)
    render(conn, "show.json", browser_session: browser_session)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id, "browser_session" => browser_session_params}) do
    browser_session = BrowserSessions.get_browser_session!(id)

    with {:ok, %BrowserSession{} = browser_session} <-
           BrowserSessions.update_browser_session(browser_session, browser_session_params) do
      render(conn, "show.json", browser_session: browser_session)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    browser_session = BrowserSessions.get_browser_session!(id)

    with {:ok, %BrowserSession{}} <- BrowserSessions.delete_browser_session(browser_session) do
      send_resp(conn, :no_content, "")
    end
  end
end
