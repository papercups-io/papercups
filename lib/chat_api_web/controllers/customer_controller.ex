defmodule ChatApiWeb.CustomerController do
  use ChatApiWeb, :controller

  alias ChatApi.{Accounts, Customers}
  alias ChatApi.Customers.Customer

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      customers = Customers.list_customers(account_id)
      render(conn, "index.#{resp_format(params)}", customers: customers)
    end
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"customer" => customer_params}) do
    params =
      customer_params
      |> Map.merge(%{
        "ip" => conn.remote_ip |> :inet_parse.ntoa() |> to_string(),
        "last_seen_at" => DateTime.utc_now()
      })
      |> Customers.sanitize_metadata()

    with {:ok, %Customer{} = customer} <- Customers.create_customer(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.customer_path(conn, :show, customer))
      |> render("show.json", customer: customer)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    customer = Customers.get_customer!(id)
    render(conn, "show.json", customer: customer)
  end

  @spec identify(Plug.Conn.t(), map) :: Plug.Conn.t()
  def identify(conn, %{
        "external_id" => external_id,
        "account_id" => account_id
      }) do
    if Accounts.exists?(account_id) do
      case Customers.find_by_external_id(external_id, account_id) do
        %{id: customer_id} ->
          json(conn, %{
            data: %{
              customer_id: customer_id
            }
          })

        _ ->
          json(conn, %{data: %{customer_id: nil}})
      end
    else
      send_account_not_found_error(conn, account_id)
    end
  end

  def identify(conn, params) do
    conn
    |> put_status(422)
    |> json(%{
      error: %{
        status: 422,
        message: "The following parameters are required: external_id, account_id",
        received: Map.keys(params)
      }
    })
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"id" => id, "customer" => customer_params}) do
    customer = Customers.get_customer!(id)

    with {:ok, %Customer{} = customer} <- Customers.update_customer(customer, customer_params) do
      render(conn, "show.json", customer: customer)
    end
  end

  @spec update_metadata(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update_metadata(conn, %{"id" => id, "metadata" => metadata}) do
    # TODO: include account_id
    customer = Customers.get_customer!(id)

    updates =
      metadata
      |> Map.merge(%{
        "ip" => conn.remote_ip |> :inet_parse.ntoa() |> to_string(),
        "last_seen_at" => DateTime.utc_now()
      })
      |> Customers.sanitize_metadata()

    with {:ok, %Customer{} = customer} <- Customers.update_customer_metadata(customer, updates) do
      render(conn, "show.json", customer: customer)
    end
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    customer = Customers.get_customer!(id)

    with {:ok, %Customer{}} <- Customers.delete_customer(customer) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec exists(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def exists(conn, %{"id" => id}) do
    # TODO: include account_id
    json(conn, %{data: Customers.exists?(id)})
  end

  @spec add_tag(Plug.Conn.t(), map) :: Plug.Conn.t()
  def add_tag(conn, %{"customer_id" => id, "tag_id" => tag_id}) do
    customer = Customers.get_customer!(id)

    with {:ok, _result} <- Customers.add_tag(customer, tag_id) do
      json(conn, %{data: %{ok: true}})
    end
  end

  @spec remove_tag(Plug.Conn.t(), map) :: Plug.Conn.t()
  def remove_tag(conn, %{"customer_id" => id, "tag_id" => tag_id}) do
    customer = Customers.get_customer!(id)

    with {:ok, _result} <- Customers.remove_tag(customer, tag_id) do
      json(conn, %{data: %{ok: true}})
    end
  end

  ###
  # Helpers
  ###

  @spec resp_format(map()) :: String.t()
  defp resp_format(%{"format" => "csv"}), do: "csv"
  defp resp_format(_), do: "json"

  @spec send_account_not_found_error(Plug.Conn.t(), binary()) :: Plug.Conn.t()
  defp send_account_not_found_error(conn, account_id) do
    conn
    |> put_status(404)
    |> json(%{
      error: %{
        status: 404,
        message: "No account found with ID: #{account_id}. Are you pointing at the correct host?",
        host: System.get_env("BACKEND_URL") || "localhost"
      }
    })
  end
end
