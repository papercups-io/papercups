defmodule ChatApiWeb.BroadcastController do
  use ChatApiWeb, :controller

  alias ChatApi.{Broadcasts, MessageTemplates}
  alias ChatApi.Broadcasts.Broadcast
  alias ChatApi.MessageTemplates.MessageTemplate

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete, :send])

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
  def show(conn, %{"id" => id}) do
    broadcast =
      Broadcasts.get_broadcast!(id, [:message_template, [broadcast_customers: :customer]])

    render(conn, "show.json", broadcast: broadcast)
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

  @spec send(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send(conn, %{"id" => _id}) do
    # TODO: move more of this logic out of the controller into the Broadcasts context
    with %{current_user: current_user, current_broadcast: broadcast} <- conn.assigns,
         %{account_id: account_id, email: email} <- current_user,
         %{message_template_id: template_id} <- broadcast,
         %{refresh_token: refresh_token} <-
           ChatApi.Google.get_support_gmail_authorization(account_id),
         %MessageTemplate{raw_html: raw_html, plain_text: plain_text} <-
           MessageTemplates.get_message_template!(template_id) do
      {:ok, broadcast} =
        Broadcasts.update_broadcast(broadcast, %{
          state: "started",
          started_at: DateTime.utc_now()
        })

      # TODO: move to worker?
      broadcast
      |> Broadcasts.list_broadcast_customers()
      |> Enum.map(fn customer ->
        data = Map.from_struct(customer)

        {:ok, text} = MessageTemplates.render(plain_text, data)
        {:ok, html} = MessageTemplates.render(raw_html, data)

        # TODO: figure out the best way to handle errors here
        # TODO: based on result, update broadcast_customer record state/sent_at fields
        ChatApi.Google.Gmail.send_message(refresh_token, %{
          to: customer.email,
          from: email,
          subject: "Test Papercups template",
          text: text,
          html: html
        })

        Broadcasts.update_broadcast_customer(broadcast, customer, %{
          state: "sent",
          sent_at: DateTime.utc_now()
        })
      end)

      {:ok, broadcast} =
        Broadcasts.update_broadcast(broadcast, %{
          state: "finished",
          finished_at: DateTime.utc_now()
        })

      render(conn, "show.json",
        broadcast:
          Broadcasts.get_broadcast!(broadcast.id, [
            :message_template,
            [broadcast_customers: :customer]
          ])
      )

      # json(conn, %{ok: true, num_sent: length(results)})
    end
  end
end
