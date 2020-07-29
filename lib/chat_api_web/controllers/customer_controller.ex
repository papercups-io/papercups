defmodule ChatApiWeb.CustomerController do
  use ChatApiWeb, :controller

  alias ChatApi.Customers
  alias ChatApi.Customers.Customer

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      customers = Customers.list_customers(account_id)
      render(conn, "index.json", customers: customers)
    end
  end

  def create(conn, %{"customer" => customer_params}) do
    ip = conn.remote_ip |> :inet_parse.ntoa() |> to_string()
    params = Map.merge(customer_params, %{"ip" => ip})

    with {:ok, %Customer{} = customer} <- Customers.create_customer(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.customer_path(conn, :show, customer))
      |> render("show.json", customer: customer)
    end
  end

  def show(conn, %{"id" => id}) do
    customer = Customers.get_customer!(id)
    render(conn, "show.json", customer: customer)
  end

  def update(conn, %{"id" => id, "customer" => customer_params}) do
    customer = Customers.get_customer!(id)

    with {:ok, %Customer{} = customer} <- Customers.update_customer(customer, customer_params) do
      render(conn, "show.json", customer: customer)
    end
  end

  def update_metadata(conn, %{"id" => id, "metadata" => metadata}) do
    customer = Customers.get_customer!(id)

    with {:ok, %Customer{} = customer} <- Customers.update_customer_metadata(customer, metadata) do
      render(conn, "show.json", customer: customer)
    end
  end

  def delete(conn, %{"id" => id}) do
    customer = Customers.get_customer!(id)

    with {:ok, %Customer{}} <- Customers.delete_customer(customer) do
      send_resp(conn, :no_content, "")
    end
  end
end
