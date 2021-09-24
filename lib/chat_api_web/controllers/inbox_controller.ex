defmodule ChatApiWeb.InboxController do
  use ChatApiWeb, :controller

  alias ChatApi.Inboxes
  alias ChatApi.Inboxes.Inbox

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete])

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         %Inbox{account_id: ^account_id} = inbox <- Inboxes.get_inbox!(id) do
      assign(conn, :current_inbox, inbox)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      inboxes = Inboxes.list_inboxes(account_id)
      render(conn, "index.json", inboxes: inboxes)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"inbox" => inbox_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         {:ok, %Inbox{} = inbox} <-
           inbox_params
           |> Map.merge(%{"account_id" => account_id})
           |> Inboxes.create_inbox() do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.inbox_path(conn, :show, inbox)
      )
      |> render("show.json", inbox: inbox)
    end
  end

  @spec primary(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def primary(conn, _params) do
    account_id = conn.assigns.current_user.account_id
    inbox = Inboxes.get_account_primary_inbox(account_id)

    render(conn, "show.json", inbox: inbox)
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => _id}) do
    render(conn, "show.json", inbox: conn.assigns.current_inbox)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => _id, "inbox" => inbox_params}) do
    with {:ok, %Inbox{} = inbox} <-
           Inboxes.update_inbox(
             conn.assigns.current_inbox,
             inbox_params
           ) do
      render(conn, "show.json", inbox: inbox)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => _id}) do
    with {:ok, %Inbox{}} <-
           Inboxes.delete_inbox(conn.assigns.current_inbox) do
      send_resp(conn, :no_content, "")
    end
  end
end
