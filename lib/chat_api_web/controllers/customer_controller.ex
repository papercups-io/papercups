defmodule ChatApiWeb.CustomerController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.{Accounts, Customers}
  alias ChatApi.Customers.Customer

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete])

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    preloads =
      (conn.params["expand"] || ["company", "tags"])
      |> Enum.map(&String.to_existing_atom/1)
      |> Enum.filter(&Customers.is_valid_association?/1)

    with %{account_id: account_id} <- conn.assigns.current_user,
         customer = %{account_id: ^account_id} <-
           Customers.get_customer!(id, preloads) do
      assign(conn, :current_customer, customer)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      page = Customers.list_customers(account_id, params, format_pagination_options(params))
      render(conn, "index.#{resp_format(params)}", page: page)
    end
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"customer" => customer_params}) do
    params =
      %{
        # Defaults
        "first_seen" => DateTime.utc_now(),
        "last_seen_at" => DateTime.utc_now(),
        # If the user is authenticated, we can use their account_id here
        "account_id" =>
          case Pow.Plug.current_user(conn) do
            %{account_id: account_id} -> account_id
            _ -> nil
          end
      }
      |> Map.merge(customer_params)
      |> Map.merge(%{"ip" => conn.remote_ip |> :inet_parse.ntoa() |> to_string()})
      |> Customers.sanitize_metadata()

    with {:ok, %Customer{} = customer} <- Customers.create_customer(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.customer_path(conn, :show, customer))
      |> render("show.json", customer: customer)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, _params) do
    render(conn, "show.json", customer: conn.assigns.current_customer)
  end

  @spec identify(Plug.Conn.t(), map) :: Plug.Conn.t()
  def identify(
        conn,
        %{
          "external_id" => external_id,
          "account_id" => account_id
        } = params
      )
      when not is_nil(external_id) and not is_nil(account_id) do
    # TODO: support whitelisting urls for an account so we only enable this and
    # other chat widget-related APIs for incoming requests from supported urls?
    if Accounts.exists?(account_id) do
      # TODO: make "host" a required param? (but would have to ignore on mobile...)
      filters =
        params
        |> Map.take(["email", "host"])
        |> Enum.reject(fn {_k, v} -> blank?(v) end)
        |> Map.new()

      case Customers.find_by_external_id(external_id, account_id, filters) do
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
  def update(conn, %{"customer" => customer_params}) do
    customer = conn.assigns.current_customer

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
        "ip" =>
          if ip_collection_enabled?() do
            conn.remote_ip |> :inet_parse.ntoa() |> to_string()
          else
            nil
          end,
        "last_seen_at" => DateTime.utc_now()
      })
      |> Customers.sanitize_metadata()

    with {:ok, %Customer{} = customer} <- Customers.update_customer_metadata(customer, updates) do
      render(conn, "show.json", customer: customer)
    end
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, _params) do
    customer = conn.assigns.current_customer

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

  @spec link_issue(Plug.Conn.t(), map) :: Plug.Conn.t()
  def link_issue(conn, %{"customer_id" => id, "issue_id" => issue_id}) do
    customer = Customers.get_customer!(id)

    with {:ok, _result} <- Customers.link_issue(customer, issue_id) do
      json(conn, %{data: %{ok: true}})
    end
  end

  @spec unlink_issue(Plug.Conn.t(), map) :: Plug.Conn.t()
  def unlink_issue(conn, %{"customer_id" => id, "issue_id" => issue_id}) do
    customer = Customers.get_customer!(id)

    with {:ok, _result} <- Customers.unlink_issue(customer, issue_id) do
      json(conn, %{data: %{ok: true}})
    end
  end

  ###
  # Helpers
  ###

  @spec blank?(binary() | nil) :: boolean()
  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false

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

  @spec ip_collection_enabled?() :: boolean()
  defp ip_collection_enabled?() do
    case System.get_env("PAPERCUPS_IP_COLLECTION_ENABLED") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end

  defp format_pagination_options(params) do
    Enum.reduce(
      params,
      %{},
      fn
        {"page", value}, acc -> Map.put(acc, :page, value)
        {"page_size", value}, acc -> Map.put(acc, :page_size, value)
        {"limit", value}, acc -> Map.put(acc, :page_size, value)
        _, acc -> acc
      end
    )
  end
end
