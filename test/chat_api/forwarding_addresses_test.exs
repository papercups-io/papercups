defmodule ChatApi.ForwardingAddressesTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.ForwardingAddresses

  describe "forwarding_addresses" do
    alias ChatApi.ForwardingAddresses.ForwardingAddress

    @update_attrs %{
      forwarding_email_address: "updated@forwarding.com",
      source_email_address: "updated@source.com",
      description: "some updated description",
      state: "some updated state"
    }
    @invalid_attrs %{
      forwarding_email_address: nil
    }

    setup do
      account = insert(:account)
      forwarding_address = insert(:forwarding_address, account: account)

      {:ok, account: account, forwarding_address: forwarding_address}
    end

    test "list_forwarding_addresses/1 returns all forwarding_addresses", %{
      account: account,
      forwarding_address: forwarding_address
    } do
      forwarding_address_ids =
        ForwardingAddresses.list_forwarding_addresses(account.id)
        |> Enum.map(& &1.id)

      assert forwarding_address_ids == [forwarding_address.id]
    end

    test "get_forwarding_address!/1 returns the forwarding_address with given id", %{
      forwarding_address: forwarding_address
    } do
      found_forwarding_address =
        ForwardingAddresses.get_forwarding_address!(forwarding_address.id)
        |> Repo.preload([:account])

      assert found_forwarding_address == forwarding_address
    end

    test "create_forwarding_address/1 with valid data creates a forwarding_address", %{
      account: account
    } do
      attrs =
        params_with_assocs(:forwarding_address,
          account: account,
          forwarding_email_address: "test@chat.papercups.io"
        )

      assert {:ok, %ForwardingAddress{forwarding_email_address: "test@chat.papercups.io"}} =
               ForwardingAddresses.create_forwarding_address(attrs)
    end

    test "create_forwarding_address/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               ForwardingAddresses.create_forwarding_address(@invalid_attrs)
    end

    test "update_forwarding_address/2 with valid data updates the forwarding_address", %{
      forwarding_address: forwarding_address
    } do
      assert {:ok, %ForwardingAddress{} = forwarding_address} =
               ForwardingAddresses.update_forwarding_address(forwarding_address, @update_attrs)

      assert forwarding_address.forwarding_email_address == "updated@forwarding.com"
      assert forwarding_address.source_email_address == "updated@source.com"
      assert forwarding_address.description == "some updated description"
      assert forwarding_address.state == "some updated state"
    end

    test "update_forwarding_address/2 with invalid data returns error changeset", %{
      forwarding_address: forwarding_address
    } do
      assert {:error, %Ecto.Changeset{}} =
               ForwardingAddresses.update_forwarding_address(forwarding_address, @invalid_attrs)

      assert forwarding_address ==
               ForwardingAddresses.get_forwarding_address!(forwarding_address.id)
               |> Repo.preload([:account])
    end

    test "delete_forwarding_address/1 deletes the forwarding_address", %{
      forwarding_address: forwarding_address
    } do
      assert {:ok, %ForwardingAddress{}} =
               ForwardingAddresses.delete_forwarding_address(forwarding_address)

      assert_raise Ecto.NoResultsError, fn ->
        ForwardingAddresses.get_forwarding_address!(forwarding_address.id)
      end
    end

    test "change_forwarding_address/1 returns a forwarding_address changeset", %{
      forwarding_address: forwarding_address
    } do
      assert %Ecto.Changeset{} = ForwardingAddresses.change_forwarding_address(forwarding_address)
    end
  end
end
