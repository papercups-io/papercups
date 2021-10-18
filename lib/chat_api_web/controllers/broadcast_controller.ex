defmodule ChatApiWeb.BroadcastController do
  use ChatApiWeb, :controller

  alias ChatApi.{Broadcasts, MessageTemplates}
  alias ChatApi.Broadcasts.Broadcast
  alias ChatApi.Google.GoogleAuthorization
  alias ChatApi.MessageTemplates.MessageTemplate

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete, :send])

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         broadcast = %Broadcast{account_id: ^account_id} <- Broadcasts.get_broadcast!(id) do
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
  def send(conn, %{"id" => _id} = payload) do
    # TODO: move more of this logic out of the controller into the Broadcasts context
    with %{current_user: current_user, current_broadcast: broadcast} <- conn.assigns,
         %{account_id: account_id, email: email} <- current_user,
         %Broadcast{message_template_id: template_id, subject: subject} <- broadcast,
         # TODO: add better error handling if no gmail authorization is available
         {:ok, %GoogleAuthorization{refresh_token: refresh_token}} <-
           get_gmail_authorization(account_id),
         %MessageTemplate{
           raw_html: raw_html,
           plain_text: plain_text,
           type: type,
           default_subject: default_subject
         } <-
           MessageTemplates.get_message_template!(template_id) do
      # If the broadcast hasn't started yet, mark that it has started
      if Broadcasts.unstarted?(broadcast) do
        Broadcasts.update_broadcast(broadcast, %{
          state: "started",
          started_at: DateTime.utc_now()
        })
      end

      filters = payload |> atomize_keys() |> Map.merge(%{state: "unsent"})
      # Get all the contacts for the broadcast and send them notifications using the template
      # TODO: move to worker?
      broadcast
      |> Broadcasts.list_broadcast_customers(filters)
      |> Enum.map(fn customer ->
        data = Map.from_struct(customer)

        {:ok, text} = MessageTemplates.render(plain_text, data)
        {:ok, html} = MessageTemplates.render(raw_html, data)

        payload = %{
          to: customer.email,
          # TODO: make it possible to specify the name (e.g. from: {name, email})
          from: email,
          # TODO: should this be set at the broadcast level or message_template level?
          subject: subject || default_subject || "Latest updates",
          text: text,
          html:
            case type do
              "plain_text" -> nil
              _ -> html
            end
        }

        # TODO: figure out the best way to handle errors here
        # TODO: based on result, update broadcast_customer record state/sent_at fields
        IO.inspect(payload, label: "Sending payload")
        ChatApi.Google.Gmail.send_message(refresh_token, payload) |> IO.inspect(label: "Sent!")

        Broadcasts.update_broadcast_customer(broadcast, customer, %{
          state: "sent",
          sent_at: DateTime.utc_now()
        })
      end)

      # If all contacts have been notified, mark the broadcast as finished
      if Broadcasts.finished?(broadcast) do
        Broadcasts.update_broadcast(broadcast, %{
          state: "finished",
          finished_at: DateTime.utc_now()
        })
      end

      render(conn, "show.json",
        broadcast:
          Broadcasts.get_broadcast!(broadcast.id, [
            :message_template,
            [broadcast_customers: :customer]
          ])
      )
    end
  end

  defp get_gmail_authorization(account_id) do
    case ChatApi.Google.get_support_gmail_authorization(account_id) do
      %GoogleAuthorization{refresh_token: _} = authorization -> {:ok, authorization}
      _ -> {:error, :forbidden, "Missing Gmail authorization"}
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      value =
        case v do
          m when is_map(m) -> atomize_keys(m)
          v -> v
        end

      {String.to_atom(k), value}
    end)
  end
end
