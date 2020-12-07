defmodule ChatApi.EventSubscriptionsTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.EventSubscriptions

  describe "event_subscriptions" do
    alias ChatApi.EventSubscriptions.EventSubscription

    @update_attrs %{
      scope: "some updated scope",
      verified: false,
      webhook_url: "some updated webhook_url"
    }
    @invalid_attrs %{account_id: nil, scope: nil, verified: nil, webhook_url: nil}

    setup do
      account = insert(:account)
      event_subscription = insert(:event_subscription, account: account)

      {:ok, account: account, event_subscription: event_subscription}
    end

    test "list_event_subscriptions/0 returns all event_subscriptions",
         %{event_subscription: event_subscription, account: account} do
      found_event_ids =
        EventSubscriptions.list_event_subscriptions(account.id)
        |> Enum.map(& &1.id)

      assert found_event_ids == [event_subscription.id]
    end

    test "get_event_subscription!/1 returns the event_subscription with given id",
         %{event_subscription: event_subscription} do
      assert EventSubscriptions.get_event_subscription!(event_subscription.id).id ==
               event_subscription.id
    end

    test "create_event_subscription/1 with valid data creates a event_subscription",
         %{account: account} do
      assert {:ok, %EventSubscription{} = event_subscription} =
               EventSubscriptions.create_event_subscription(
                 params_for(:event_subscription, account: account, verified: true)
               )

      assert event_subscription.account_id == account.id
      assert event_subscription.scope == "some scope"
      assert event_subscription.verified == true
      assert event_subscription.webhook_url == "some webhook_url"
    end

    test "create_event_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               EventSubscriptions.create_event_subscription(@invalid_attrs)
    end

    test "update_event_subscription/2 with valid data updates the event_subscription",
         %{event_subscription: event_subscription} do
      assert {:ok, %EventSubscription{} = event_subscription} =
               EventSubscriptions.update_event_subscription(event_subscription, @update_attrs)

      assert event_subscription.scope == "some updated scope"
      assert event_subscription.verified == false
      assert event_subscription.webhook_url == "some updated webhook_url"
    end

    test "update_event_subscription/2 with invalid data returns error changeset",
         %{event_subscription: event_subscription} do
      assert {:error, %Ecto.Changeset{}} =
               EventSubscriptions.update_event_subscription(event_subscription, @invalid_attrs)

      assert event_subscription ==
               EventSubscriptions.get_event_subscription!(event_subscription.id)
               |> Repo.preload([:account])
    end

    test "delete_event_subscription/1 deletes the event_subscription",
         %{event_subscription: event_subscription} do
      assert {:ok, %EventSubscription{}} =
               EventSubscriptions.delete_event_subscription(event_subscription)

      assert_raise Ecto.NoResultsError, fn ->
        EventSubscriptions.get_event_subscription!(event_subscription.id)
      end
    end

    test "change_event_subscription/1 returns a event_subscription changeset",
         %{event_subscription: event_subscription} do
      assert %Ecto.Changeset{} = EventSubscriptions.change_event_subscription(event_subscription)
    end
  end
end
