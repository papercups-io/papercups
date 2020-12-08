defmodule ChatApiWeb.EventSubscriptionControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.EventSubscriptions.EventSubscription

  @create_attrs params_for(:event_subscription)
  @update_attrs %{
    scope: "some updated scope",
    webhook_url: "some updated webhook_url"
  }
  @invalid_attrs %{account_id: nil, scope: nil, verified: nil, webhook_url: nil}

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    subscription = insert(:event_subscription, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok,
     conn: conn, authed_conn: authed_conn, account: account, event_subscription: subscription}
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all event_subscriptions",
         %{authed_conn: authed_conn, event_subscription: subscription} do
      resp = get(authed_conn, Routes.event_subscription_path(authed_conn, :index))
      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])
      assert ids == [subscription.id]
    end
  end

  describe "create event_subscription" do
    test "renders event_subscription when data is valid",
         %{authed_conn: authed_conn} do
      resp =
        post(authed_conn, Routes.event_subscription_path(authed_conn, :create),
          event_subscription: @create_attrs
        )

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.event_subscription_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "object" => "event_subscription",
               "scope" => "some scope",
               "webhook_url" => "some webhook_url"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      resp =
        post(authed_conn, Routes.event_subscription_path(authed_conn, :create),
          event_subscription: @invalid_attrs
        )

      assert json_response(resp, 422)["errors"] != %{}
    end
  end

  describe "update event_subscription" do
    test "renders event_subscription when data is valid",
         %{
           authed_conn: authed_conn,
           event_subscription: %EventSubscription{id: id} = event_subscription
         } do
      conn =
        put(authed_conn, Routes.event_subscription_path(authed_conn, :update, event_subscription),
          event_subscription: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.event_subscription_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "scope" => "some updated scope",
               "webhook_url" => "some updated webhook_url"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid",
         %{authed_conn: authed_conn, event_subscription: event_subscription} do
      conn =
        put(authed_conn, Routes.event_subscription_path(authed_conn, :update, event_subscription),
          event_subscription: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete event_subscription" do
    test "deletes chosen event_subscription",
         %{authed_conn: authed_conn, event_subscription: event_subscription} do
      conn =
        delete(
          authed_conn,
          Routes.event_subscription_path(authed_conn, :delete, event_subscription)
        )

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.event_subscription_path(authed_conn, :show, event_subscription))
      end
    end
  end
end
