defmodule ChatApi.EventSubscriptionsTest do
  use ChatApi.DataCase

  alias ChatApi.{Accounts, EventSubscriptions}

  describe "event_subscriptions" do
    alias ChatApi.EventSubscriptions.EventSubscription

    @valid_attrs %{
      scope: "some scope",
      verified: true,
      webhook_url: "some webhook_url"
    }
    @update_attrs %{
      scope: "some updated scope",
      verified: false,
      webhook_url: "some updated webhook_url"
    }
    @invalid_attrs %{account_id: nil, scope: nil, verified: nil, webhook_url: nil}

    def event_subscription_fixture(attrs \\ %{}) do
      %{id: account_id} = account_fixture()

      {:ok, event_subscription} =
        attrs
        |> Enum.into(%{account_id: account_id})
        |> Enum.into(@valid_attrs)
        |> EventSubscriptions.create_event_subscription()

      event_subscription
    end

    def account_fixture(attrs \\ %{}) do
      {:ok, account} =
        %{company_name: "Test Inc"}
        |> Enum.into(attrs)
        |> Accounts.create_account()

      account
    end

    setup do
      account = account_fixture()

      {:ok, account: account}
    end

    test "list_event_subscriptions/0 returns all event_subscriptions", %{account: account} do
      event_subscription = event_subscription_fixture(%{account_id: account.id})
      assert EventSubscriptions.list_event_subscriptions(account.id) == [event_subscription]
    end

    test "get_event_subscription!/1 returns the event_subscription with given id" do
      event_subscription = event_subscription_fixture()

      assert EventSubscriptions.get_event_subscription!(event_subscription.id) ==
               event_subscription
    end

    test "create_event_subscription/1 with valid data creates a event_subscription", %{
      account: account
    } do
      attrs = Map.merge(@valid_attrs, %{account_id: account.id})

      assert {:ok, %EventSubscription{} = event_subscription} =
               EventSubscriptions.create_event_subscription(attrs)

      assert event_subscription.account_id == account.id
      assert event_subscription.scope == "some scope"
      assert event_subscription.verified == true
      assert event_subscription.webhook_url == "some webhook_url"
    end

    test "create_event_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               EventSubscriptions.create_event_subscription(@invalid_attrs)
    end

    test "update_event_subscription/2 with valid data updates the event_subscription" do
      event_subscription = event_subscription_fixture()

      assert {:ok, %EventSubscription{} = event_subscription} =
               EventSubscriptions.update_event_subscription(event_subscription, @update_attrs)

      assert event_subscription.scope == "some updated scope"
      assert event_subscription.verified == false
      assert event_subscription.webhook_url == "some updated webhook_url"
    end

    test "update_event_subscription/2 with invalid data returns error changeset" do
      event_subscription = event_subscription_fixture()

      assert {:error, %Ecto.Changeset{}} =
               EventSubscriptions.update_event_subscription(event_subscription, @invalid_attrs)

      assert event_subscription ==
               EventSubscriptions.get_event_subscription!(event_subscription.id)
    end

    test "delete_event_subscription/1 deletes the event_subscription" do
      event_subscription = event_subscription_fixture()

      assert {:ok, %EventSubscription{}} =
               EventSubscriptions.delete_event_subscription(event_subscription)

      assert_raise Ecto.NoResultsError, fn ->
        EventSubscriptions.get_event_subscription!(event_subscription.id)
      end
    end

    test "change_event_subscription/1 returns a event_subscription changeset" do
      event_subscription = event_subscription_fixture()
      assert %Ecto.Changeset{} = EventSubscriptions.change_event_subscription(event_subscription)
    end
  end
end
