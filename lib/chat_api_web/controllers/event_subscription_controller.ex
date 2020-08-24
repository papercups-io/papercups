defmodule ChatApiWeb.EventSubscriptionController do
  use ChatApiWeb, :controller

  alias ChatApi.EventSubscriptions
  alias ChatApi.EventSubscriptions.EventSubscription

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      event_subscriptions = EventSubscriptions.list_event_subscriptions(account_id)
      render(conn, "index.json", event_subscriptions: event_subscriptions)
    end
  end

  def create(conn, %{"event_subscription" => event_subscription_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         params <- Map.merge(event_subscription_params, %{"account_id" => account_id}),
         {:ok, %EventSubscription{} = event_subscription} <-
           EventSubscriptions.create_event_subscription(params) do
      # Not sure the most appropriate place to handle this verification :shrug:
      verified =
        event_subscription
        |> Map.get(:webhook_url)
        |> EventSubscriptions.is_valid_webhook_url?()

      {:ok, result} =
        EventSubscriptions.update_event_subscription(event_subscription, %{verified: verified})

      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.event_subscription_path(conn, :show, result)
      )
      |> render("show.json", event_subscription: result)
    end
  end

  def show(conn, %{"id" => id}) do
    event_subscription = EventSubscriptions.get_event_subscription!(id)
    render(conn, "show.json", event_subscription: event_subscription)
  end

  def update(conn, %{"id" => id, "event_subscription" => event_subscription_params}) do
    event_subscription = EventSubscriptions.get_event_subscription!(id)

    with {:ok, %EventSubscription{} = event_subscription} <-
           EventSubscriptions.update_event_subscription(
             event_subscription,
             event_subscription_params
           ) do
      render(conn, "show.json", event_subscription: event_subscription)
    end
  end

  def delete(conn, %{"id" => id}) do
    event_subscription = EventSubscriptions.get_event_subscription!(id)

    with {:ok, %EventSubscription{}} <-
           EventSubscriptions.delete_event_subscription(event_subscription) do
      send_resp(conn, :no_content, "")
    end
  end

  def verify(conn, %{"url" => url}) do
    verified = EventSubscriptions.is_valid_webhook_url?(url)

    json(conn, %{
      data: %{
        verified: verified
      }
    })
  end
end
