defmodule ChatApiWeb.BroadcastController do
  use ChatApiWeb, :controller

  alias ChatApi.Broadcasts
  alias ChatApi.Broadcasts.Broadcast

  action_fallback ChatApiWeb.FallbackController

  plug :authorize when action in [:show, :update, :delete]

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         broadcast = %{account_id: ^account_id} <- Broadcasts.get_broadcast!(id) do
      assign(conn, :current_broadcast, broadcast)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      broadcasts = Broadcasts.list_broadcasts(account_id)
      render(conn, "index.json", broadcasts: broadcasts)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"broadcast" => broadcast_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         {:ok, %Broadcast{} = broadcast} <-
           broadcast_params
           |> Map.merge(%{"account_id" => account_id})
           |> Broadcasts.create_broadcast() do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.broadcast_path(conn, :show, broadcast))
      |> render("show.json", broadcast: broadcast)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => _id}) do
    render(conn, "show.json", broadcast: conn.assigns.current_broadcast)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => _id, "broadcast" => broadcast_params}) do
    with {:ok, %Broadcast{} = broadcast} <-
           Broadcasts.update_broadcast(
             conn.assigns.current_broadcast,
             broadcast_params
           ) do
      render(conn, "show.json", broadcast: broadcast)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => _id}) do
    with {:ok, %Broadcast{}} <-
           Broadcasts.delete_broadcast(conn.assigns.current_broadcast) do
      send_resp(conn, :no_content, "")
    end
  end
end
