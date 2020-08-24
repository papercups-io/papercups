defmodule ChatApiWeb.EventSubscriptionControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.{Accounts, EventSubscriptions}
  alias ChatApi.EventSubscriptions.EventSubscription

  @create_attrs %{
    scope: "some scope",
    webhook_url: "some webhook_url"
  }
  @update_attrs %{
    scope: "some updated scope",
    webhook_url: "some updated webhook_url"
  }
  @invalid_attrs %{account_id: nil, scope: nil, verified: nil, webhook_url: nil}

  def fixture(:event_subscription) do
    account = fixture(:account)

    {:ok, event_subscription} =
      @create_attrs
      |> Enum.into(%{account_id: account.id})
      |> EventSubscriptions.create_event_subscription()

    event_subscription
  end

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    account
  end

  setup %{conn: conn} do
    account = fixture(:account)
    user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all event_subscriptions", %{authed_conn: authed_conn} do
      resp = get(authed_conn, Routes.event_subscription_path(authed_conn, :index))
      assert json_response(resp, 200)["data"] == []
    end
  end

  describe "create event_subscription" do
    test "renders event_subscription when data is valid", %{authed_conn: authed_conn} do
      resp =
        post(authed_conn, Routes.event_subscription_path(authed_conn, :create),
          event_subscription: @create_attrs
        )

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.event_subscription_path(authed_conn, :show, id))

      assert %{
               "id" => id,
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
    setup [:create_event_subscription]

    test "renders event_subscription when data is valid", %{
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
               "id" => id,
               "scope" => "some updated scope",
               "webhook_url" => "some updated webhook_url"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      event_subscription: event_subscription
    } do
      conn =
        put(authed_conn, Routes.event_subscription_path(authed_conn, :update, event_subscription),
          event_subscription: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete event_subscription" do
    setup [:create_event_subscription]

    test "deletes chosen event_subscription", %{
      authed_conn: authed_conn,
      event_subscription: event_subscription
    } do
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

  defp create_event_subscription(_) do
    event_subscription = fixture(:event_subscription)
    %{event_subscription: event_subscription}
  end
end
