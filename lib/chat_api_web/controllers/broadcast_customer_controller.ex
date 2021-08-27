defmodule ChatApiWeb.BroadcastCustomerController do
  use ChatApiWeb, :controller

  alias ChatApi.Broadcasts
  alias ChatApi.Customers.Customer
  alias ChatApiWeb.CustomerView

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:index, :create, :delete])

  defp authorize(conn, _) do
    id = conn.path_params["broadcast_id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         broadcast = %{account_id: ^account_id} <- Broadcasts.get_broadcast!(id) do
      assign(conn, :current_broadcast, broadcast)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    broadcast = conn.assigns.current_broadcast
    customers = Broadcasts.list_broadcast_customers(broadcast)

    conn
    |> put_view(CustomerView)
    |> render("list.json", customers: customers)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"customers" => customer_ids} = params) do
    broadcast = conn.assigns.current_broadcast

    {count, nil} =
      case Map.get(params, "action", "replace") do
        "add" -> Broadcasts.add_broadcast_customers(broadcast, customer_ids)
        "replace" -> Broadcasts.set_broadcast_customers(broadcast, customer_ids)
        _ -> Broadcasts.set_broadcast_customers(broadcast, customer_ids)
      end

    json(conn, %{data: %{count: count}})
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"customer_id" => customer_id}) do
    with %{current_broadcast: broadcast} <- conn.assigns,
         {:ok, %Customer{}} <-
           Broadcasts.remove_broadcast_customer(broadcast, customer_id) do
      send_resp(conn, :no_content, "")
    end
  end
end
