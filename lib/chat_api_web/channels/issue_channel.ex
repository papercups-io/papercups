defmodule ChatApiWeb.IssueChannel do
  use ChatApiWeb, :channel

  @impl true
  @spec join(binary(), map(), Phoenix.Socket.t()) :: {:ok, Phoenix.Socket.t()}
  def join("issue:lobby:" <> customer_id, _params, socket) do
    if authorized?(socket, customer_id) do
      {:ok, assign(socket, :customer_id, customer_id)}
    else
      {:error, %{reason: "Unauthorized"}}
    end
  end

  @spec authorized?(Phoenix.Socket.t(), binary()) :: boolean()
  defp authorized?(socket, customer_id) do
    customer = ChatApi.Customers.get_customer!(customer_id, [])

    case socket.assigns.current_user do
      %{account_id: account_id} -> account_id == customer.account_id
      _ -> false
    end
  end
end
