defmodule ChatApi.BroadcastsTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.Broadcasts

  describe "companies" do
    alias ChatApi.Broadcasts.Broadcast

    @update_attrs %{
      name: "some updated name",
      description: "some updated description",
      started_at: ~U[2011-05-18 15:01:01Z],
      finished_at: ~U[2011-05-18 15:02:01Z],
      state: "active"
    }
    @invalid_attrs %{name: nil, state: nil}

    setup do
      account = insert(:account)
      broadcast = insert(:broadcast, account: account, message_template: nil)

      {:ok, account: account, broadcast: broadcast}
    end

    test "list_broadcasts/1 returns all companies", %{
      account: account,
      broadcast: broadcast
    } do
      broadcast_ids =
        Broadcasts.list_broadcasts(account.id)
        |> Enum.map(& &1.id)

      assert broadcast_ids == [broadcast.id]
    end

    test "get_broadcast!/1 returns the broadcast with given id", %{
      broadcast: broadcast
    } do
      found_broadcast =
        Broadcasts.get_broadcast!(broadcast.id)
        |> Repo.preload([:account, :message_template])

      assert found_broadcast == broadcast
    end

    test "create_broadcast/1 with valid data creates a broadcast", %{
      account: account
    } do
      attrs = params_with_assocs(:broadcast, account: account, name: "Test Broadcast")

      assert {:ok, %Broadcast{name: "Test Broadcast"}} = Broadcasts.create_broadcast(attrs)
    end

    test "create_broadcast/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Broadcasts.create_broadcast(@invalid_attrs)
    end

    test "update_broadcast/2 with valid data updates the broadcast", %{
      broadcast: broadcast
    } do
      assert {:ok, %Broadcast{} = broadcast} =
               Broadcasts.update_broadcast(broadcast, @update_attrs)

      assert broadcast.name == "some updated name"
      assert broadcast.description == "some updated description"
      assert broadcast.started_at == ~U[2011-05-18 15:01:01Z]
      assert broadcast.finished_at == ~U[2011-05-18 15:02:01Z]
      assert broadcast.state == "active"
    end

    test "update_broadcast/2 with invalid data returns error changeset", %{
      broadcast: broadcast
    } do
      assert {:error, %Ecto.Changeset{}} = Broadcasts.update_broadcast(broadcast, @invalid_attrs)

      assert broadcast ==
               Broadcasts.get_broadcast!(broadcast.id)
               |> Repo.preload([:account, :message_template])
    end

    test "delete_broadcast/1 deletes the broadcast", %{
      broadcast: broadcast
    } do
      assert {:ok, %Broadcast{}} = Broadcasts.delete_broadcast(broadcast)

      assert_raise Ecto.NoResultsError, fn ->
        Broadcasts.get_broadcast!(broadcast.id)
      end
    end

    test "change_broadcast/1 returns a broadcast changeset", %{
      broadcast: broadcast
    } do
      assert %Ecto.Changeset{} = Broadcasts.change_broadcast(broadcast)
    end
  end
end
