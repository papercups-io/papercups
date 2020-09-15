defmodule ChatApi.CustomersTest do
  use ChatApi.DataCase

  alias ChatApi.Customers
  alias ChatApi.Accounts

  describe "customers" do
    alias ChatApi.Customers.Customer

    @valid_attrs %{
      first_seen: ~D[2020-01-01],
      last_seen: ~D[2020-01-01]
    }
    @update_attrs %{
      first_seen: ~D[2020-01-01],
      last_seen: ~D[2020-01-02],
      name: "Test User",
      email: "user@test.com",
      phone: "+16501235555"
    }
    @invalid_attrs %{
      first_seen: 3
    }

    def add_account_id(attrs) do
      account = account_fixture()

      Enum.into(attrs, %{account_id: account.id})
    end

    def account_fixture(_attrs \\ %{}) do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

      account
    end

    def customer_fixture(attrs \\ %{}) do
      {:ok, customer} =
        attrs
        |> Enum.into(@valid_attrs)
        |> add_account_id()
        |> Customers.create_customer()

      customer
    end

    test "list_customers/1 returns all customers" do
      customer = customer_fixture()
      account_id = customer.account_id

      assert Customers.list_customers(account_id) == [customer]
    end

    test "get_customer!/1 returns the customer with given id" do
      customer = customer_fixture()
      assert Customers.get_customer!(customer.id) == customer
    end

    test "create_customer/1 with valid data creates a customer" do
      assert {:ok,
              %Customer{
                first_seen: ~D[2020-01-01],
                last_seen: ~D[2020-01-01]
              } = customer} = Customers.create_customer(add_account_id(@valid_attrs))
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Customers.create_customer(@invalid_attrs)
    end

    test "update_customer/2 with valid data updates the customer" do
      customer = customer_fixture()
      assert {:ok, %Customer{} = customer} = Customers.update_customer(customer, @update_attrs)

      assert customer.email == @update_attrs.email
      assert customer.name == @update_attrs.name
      assert customer.phone == @update_attrs.phone
    end

    test "update_customer_metadata/2 only updates customizable fields" do
      customer = customer_fixture()
      new_account = account_fixture()
      attrs = Enum.into(@update_attrs, %{account_id: new_account.id})

      assert {:ok, %Customer{} = customer} = Customers.update_customer_metadata(customer, attrs)

      assert customer.email == @update_attrs.email
      assert customer.name == @update_attrs.name
      assert customer.phone == @update_attrs.phone

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

    test "update_customer/2 with invalid data returns error changeset" do
      customer = customer_fixture()
      assert {:error, %Ecto.Changeset{}} = Customers.update_customer(customer, @invalid_attrs)
      assert customer == Customers.get_customer!(customer.id)
    end

    test "delete_customer/1 deletes the customer" do
      customer = customer_fixture()
      assert {:ok, %Customer{}} = Customers.delete_customer(customer)
      assert_raise Ecto.NoResultsError, fn -> Customers.get_customer!(customer.id) end
    end

    test "change_customer/1 returns a customer changeset" do
      customer = customer_fixture()
      assert %Ecto.Changeset{} = Customers.change_customer(customer)
    end

    test "find_by_external_id/2 returns a customer by external_id" do
      external_id = "cus_123"
      customer = customer_fixture(%{external_id: external_id})
      account_id = customer.account_id

      assert customer = Customers.find_by_external_id(external_id, account_id)
    end

    test "find_by_external_id/2 works with integer external_ids" do
      external_id = "123"
      customer = customer_fixture(%{external_id: external_id})
      account_id = customer.account_id

      assert customer = Customers.find_by_external_id(123, account_id)
    end
  end
end
