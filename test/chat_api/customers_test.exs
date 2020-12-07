defmodule ChatApi.CustomersTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.Customers

  describe "customers" do
    alias ChatApi.Customers.Customer

    @update_attrs %{
      first_seen: ~D[2020-01-01],
      last_seen: ~D[2020-01-02],
      name: "Test User",
      email: "user@test.com",
      phone: "+16501235555",
      time_zone: "America/New_York",
      current_url:
        "http://test.com/ls2bPjyYDELWL6VRpDKs9K6MrRv3O7E3F4XNZs7z4_A9gyLwBXsBZprWanwpRRNamQNFRCz9zWkixYgBPRq4mb79RF_153UHxpMg1Ct-uDfQ6SwnEGiwheWI8SraUwuEjs_GD8Cm85ziMEdFkrzNfj9NqpFOQch91YSq3wTq-7PDV4nbNd2z-IGW4CpQgXKS7DNWvrA6yKOgCSmI2OXqFNX_-PLrCseuWNJH6aYXPBKrlVZxzwOtobFV1vgWafoe",
      pathname:
        "/test/ls2bPjyYDELWL6VRpDKs9K6MrRv3O7E3F4XNZs7z4_A9gyLwBXsBZprWanwpRRNamQNFRCz9zWkixYgBPRq4mb79RF_153UHxpMg1Ct-uDfQ6SwnEGiwheWI8SraUwuEjs_GD8Cm85ziMEdFkrzNfj9NqpFOQch91YSq3wTq-7PDV4nbNd2z-IGW4CpQgXKS7DNWvrA6yKOgCSmI2OXqFNX_-PLrCseuWNJH6aYXPBKrlVZxzwOtobFV1vgWafoe"
    }
    @invalid_attrs %{
      first_seen: 3
    }

    setup do
      account = insert(:account)
      customer = insert(:customer, account: account)

      {:ok, account: account, customer: customer}
    end

    test "list_customers/1 returns all customers",
         %{account: account, customer: customer} do
      customer_ids =
        Customers.list_customers(account.id)
        |> Enum.map(& &1.id)

      assert customer_ids == [customer.id]
    end

    test "get_customer!/1 returns the customer with given id",
         %{customer: customer} do
      found_customer =
        Customers.get_customer!(customer.id)
        |> Repo.preload([:account])

      assert found_customer == customer
    end

    test "create_customer/1 with valid data creates a customer" do
      attrs = params_with_assocs(:customer)

      assert {:ok,
              %Customer{
                first_seen: ~D[2020-01-01],
                last_seen: ~D[2020-01-01]
              } = _customer} = Customers.create_customer(attrs)
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Customers.create_customer(@invalid_attrs)
    end

    test "update_customer/2 with valid data updates the customer",
         %{customer: customer} do
      assert {:ok, %Customer{} = customer} = Customers.update_customer(customer, @update_attrs)

      assert customer.email == @update_attrs.email
      assert customer.name == @update_attrs.name
      assert customer.phone == @update_attrs.phone
      assert customer.time_zone == @update_attrs.time_zone
      assert customer.current_url == @update_attrs.current_url
      assert customer.pathname == @update_attrs.pathname
    end

    test "update_customer_metadata/2 only updates customizable fields",
         %{customer: customer} do
      new_account = insert(:account)
      attrs = Enum.into(@update_attrs, %{account_id: new_account.id})

      assert {:ok, %Customer{} = customer} = Customers.update_customer_metadata(customer, attrs)

      assert customer.email == @update_attrs.email
      assert customer.name == @update_attrs.name
      assert customer.phone == @update_attrs.phone
      assert customer.time_zone == @update_attrs.time_zone

      # `account_id` should not be customizable through this API
      assert customer.account_id != new_account.id
    end

    test "sanitize_metadata/1 ensures external_id is always a string" do
      assert %{"external_id" => nil} = Customers.sanitize_metadata(%{"external_id" => nil})
      assert %{"external_id" => "123"} = Customers.sanitize_metadata(%{"external_id" => "123"})
      assert %{"external_id" => "123"} = Customers.sanitize_metadata(%{"external_id" => 123})
    end

    test "sanitize_metadata/1 truncates the current_url if it is too long" do
      current_url =
        "http://example.com/login?next=/insights%3Finsight%3DTRENDS%26interval%3Dday%26events%3D%255B%257B%2522id%2522%253A%2522%2524pageview%2522%252C%2522name%2522%253A%2522%2524pageview%2522%252C%2522type%2522%253A%2522events%2522%252C%2522order%2522%253A0%252C%2522math%2522%253A%2522total%2522%257D%255D%26display%3DActionsTable%26actions%3D%255B%255D%26new_entity%3D%255B%255D%26breakdown%3D%2524browser%26breakdown_type%3Devent%26properties%3D%255B%255D"

      assert %{"current_url" => truncated} =
               Customers.sanitize_metadata(%{"current_url" => current_url})

      assert String.length(truncated) <= 255
    end

    test "update_customer/2 with invalid data returns error changeset",
         %{customer: customer} do
      assert {:error, %Ecto.Changeset{}} = Customers.update_customer(customer, @invalid_attrs)

      assert customer ==
               Customers.get_customer!(customer.id)
               |> Repo.preload([:account])
    end

    test "delete_customer/1 deletes the customer", %{customer: customer} do
      assert {:ok, %Customer{}} = Customers.delete_customer(customer)
      assert_raise Ecto.NoResultsError, fn -> Customers.get_customer!(customer.id) end
    end

    test "change_customer/1 returns a customer changeset",
         %{customer: customer} do
      assert %Ecto.Changeset{} = Customers.change_customer(customer)
    end

    test "find_by_external_id/2 returns a customer by external_id",
         %{account: account} do
      external_id = "cus_123"
      _customer = insert(:customer, %{external_id: external_id, account: account})

      assert _customer = Customers.find_by_external_id(external_id, account.id)
    end

    test "find_by_external_id/2 works with integer external_ids",
         %{account: account} do
      external_id = "123"
      _customer = insert(:customer, %{external_id: external_id, account: account})

      assert _customer = Customers.find_by_external_id(123, account.id)
    end
  end
end
