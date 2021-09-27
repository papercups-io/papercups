defmodule ChatApiWeb.ForwardingAddressController do
  use ChatApiWeb, :controller

  alias ChatApi.ForwardingAddresses
  alias ChatApi.ForwardingAddresses.ForwardingAddress

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete])

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         %ForwardingAddress{account_id: ^account_id} = forwarding_address <-
           ForwardingAddresses.get_forwarding_address!(id) do
      assign(conn, :current_forwarding_address, forwarding_address)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      forwarding_addresses = ForwardingAddresses.list_forwarding_addresses(account_id, params)
      render(conn, "index.json", forwarding_addresses: forwarding_addresses)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"forwarding_address" => forwarding_address_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         {:ok, %ForwardingAddress{} = forwarding_address} <-
           %{
             "forwarding_email_address" => ForwardingAddresses.generate_forwarding_email_address()
           }
           |> Map.merge(forwarding_address_params)
           |> Map.merge(%{"account_id" => account_id})
           |> ForwardingAddresses.create_forwarding_address() do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.forwarding_address_path(conn, :show, forwarding_address)
      )
      |> render("show.json", forwarding_address: forwarding_address)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => _id}) do
    render(conn, "show.json", forwarding_address: conn.assigns.current_forwarding_address)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => _id, "forwarding_address" => forwarding_address_params}) do
    with {:ok, %ForwardingAddress{} = forwarding_address} <-
           ForwardingAddresses.update_forwarding_address(
             conn.assigns.current_forwarding_address,
             forwarding_address_params
           ) do
      render(conn, "show.json", forwarding_address: forwarding_address)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => _id}) do
    with {:ok, %ForwardingAddress{}} <-
           ForwardingAddresses.delete_forwarding_address(conn.assigns.current_forwarding_address) do
      send_resp(conn, :no_content, "")
    end
  end
end
