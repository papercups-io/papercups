defmodule ChatApi.CustomersTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.Customers

  describe "customers" do
    alias ChatApi.Customers.Customer

    @update_attrs %{
      first_seen: ~D[2020-01-01],
      last_seen_at: ~U[2020-01-05 00:00:00Z],
      name: "Test User",
      email: "user@test.com",
      phone: "+16501235555",
      time_zone: "America/New_York",
      profile_photo_url: "https://photo.jpg",
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
      customer = insert(:customer, account: account, company: nil)

      {:ok, account: account, customer: customer}
    end

    test "list_customers/2 returns all customers", %{account: account, customer: customer} do
      customer_ids =
        Customers.list_customers(account.id)
        |> Enum.map(& &1.id)

      assert customer_ids == [customer.id]
    end

    test "list_customers/2 can filter by company_id", %{account: account} do
      company = insert(:company, account: account)
      new_customer = insert(:customer, account: account, company: company)

      customer_ids =
        Customers.list_customers(account.id, %{"company_id" => company.id})
        |> Enum.map(& &1.id)

      assert customer_ids == [new_customer.id]
    end

    test "list_customers/2 can filter by customer tags", %{account: account} do
      customer_1 = insert(:customer, account: account, company: nil)
      customer_2 = insert(:customer, account: account, company: nil)
      tag_1 = insert(:tag, account: account)
      tag_2 = insert(:tag, account: account)
      tag_3 = insert(:tag, account: account)

      # customer_1 has two tags: tag_1 and tag_2
      insert(:customer_tag, customer: customer_1, tag: tag_1)
      insert(:customer_tag, customer: customer_1, tag: tag_2)

      # customer_2 has two tags: tag_1 and tag_3
      insert(:customer_tag, customer: customer_2, tag: tag_1)
      insert(:customer_tag, customer: customer_2, tag: tag_3)

      # Filtering with a tag that multiple customers have
      customer_ids =
        Customers.list_customers(account.id, %{"tag_ids" => [tag_1.id]})
        |> Enum.map(& &1.id)

      assert Enum.sort(customer_ids) == Enum.sort([customer_1.id, customer_2.id])

      # Filtering with multiple tags only returns customers who have all of them
      customer_ids =
        Customers.list_customers(account.id, %{"tag_ids" => [tag_1.id, tag_2.id]})
        |> Enum.map(& &1.id)

      assert customer_ids == [customer_1.id]

      # Filtering with a single tag that only one customer has
      customer_ids =
        Customers.list_customers(account.id, %{"tag_ids" => [tag_3.id]})
        |> Enum.map(& &1.id)

      assert customer_ids == [customer_2.id]
    end

    test "list_customers/2 can search by name/email", %{account: account} do
      alex = insert(:customer, account: account, name: "Alex Reichert")
      alexis = insert(:customer, account: account, name: "Alexis O'Hare")
      kam = insert(:customer, account: account, email: "kam@kam.com")

      alex_ids =
        account.id
        |> Customers.list_customers(%{"name" => "%alex%"})
        |> Enum.map(& &1.id)

      kam_ids =
        account.id
        |> Customers.list_customers(%{"email" => "%kam%"})
        |> Enum.map(& &1.id)

      assert Enum.sort(alex_ids) == Enum.sort([alex.id, alexis.id])
      assert kam_ids == [kam.id]
    end

    test "list_customers/2 can search by name/email with the `q` query param", %{account: account} do
      alex = insert(:customer, account: account, name: "Alex Reichert")
      alexis = insert(:customer, account: account, name: "Alexis O'Hare")
      kam = insert(:customer, account: account, email: "kam@kam.com")

      alex_ids =
        account.id
        |> Customers.list_customers(%{"q" => "alex"})
        |> Enum.map(& &1.id)

      kam_ids =
        account.id
        |> Customers.list_customers(%{"q" => "kam"})
        |> Enum.map(& &1.id)

      assert Enum.sort(alex_ids) == Enum.sort([alex.id, alexis.id])
      assert kam_ids == [kam.id]
    end

    test "list_customers/2 can search customer metadata within the `q` query param", %{
      account: account
    } do
      premium_dev =
        insert(:customer,
          account: account,
          metadata: %{plan: "premium", role: "dev"}
        )

      starter_dev =
        insert(:customer,
          account: account,
          metadata: %{plan: "starter", role: "dev"}
        )

      premium_pm =
        insert(:customer,
          account: account,
          metadata: %{plan: "premium", role: "pm"}
        )

      dev_ids =
        account.id
        |> Customers.list_customers(%{"q" => "role:dev"})
        |> Enum.map(& &1.id)

      premium_ids =
        account.id
        |> Customers.list_customers(%{"q" => "plan:premium"})
        |> Enum.map(& &1.id)

      starter_dev_ids =
        account.id
        |> Customers.list_customers(%{"q" => "role:dev plan:starter"})
        |> Enum.map(& &1.id)

      assert Enum.sort(dev_ids) == Enum.sort([premium_dev.id, starter_dev.id])
      assert Enum.sort(premium_ids) == Enum.sort([premium_dev.id, premium_pm.id])
      assert starter_dev_ids == [starter_dev.id]
      assert [] == Customers.list_customers(account.id, %{"q" => "role:ceo plan:starter"})
    end

    test "list_customers/3 returns paginated customers" do
      account = insert(:account)
      insert_list(10, :customer, account: account)

      page = Customers.list_customers(account.id, %{}, %{})
      page_with_params = Customers.list_customers(account.id, %{}, %{page: 2, page_size: 5})

      assert Enum.all?(page.entries, &(&1.account_id == account.id))

      assert page.total_entries == 10
      assert page.total_pages == 1

      assert page_with_params.page_number == 2
      assert page_with_params.page_size == 5
      assert page_with_params.total_pages == 2
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
                last_seen_at: ~U[2020-01-05 00:00:00Z]
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
      assert customer.profile_photo_url == @update_attrs.profile_photo_url
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

    test "update_customer/2 with invalid data returns error changeset", %{customer: customer} do
      assert {:error, %Ecto.Changeset{}} = Customers.update_customer(customer, @invalid_attrs)

      assert customer ==
               Customers.get_customer!(customer.id)
               |> Repo.preload([:account])
    end

    test "delete_customer/1 deletes the customer", %{customer: customer} do
      assert {:ok, %Customer{}} = Customers.delete_customer(customer)
      assert_raise Ecto.NoResultsError, fn -> Customers.get_customer!(customer.id) end
    end

    test "change_customer/1 returns a customer changeset", %{customer: customer} do
      assert %Ecto.Changeset{} = Customers.change_customer(customer)
    end

    test "find_by_external_id/3 returns a customer by external_id", %{account: account} do
      external_id = "cus_123"
      %{id: customer_id} = insert(:customer, %{external_id: external_id, account: account})

      assert %Customer{id: ^customer_id} = Customers.find_by_external_id(external_id, account.id)
    end

    test "find_by_external_id/3 works with integer external_ids", %{account: account} do
      external_id = "123"
      %{id: customer_id} = insert(:customer, %{external_id: external_id, account: account})

      assert %Customer{id: ^customer_id} = Customers.find_by_external_id(123, account.id)
    end

    test "find_by_external_id/3 can filter by email and host", %{account: account} do
      external_id = "123"
      email = "test@test.com"
      host = "app.chat.com"

      %{id: customer_id} =
        insert(:customer, %{
          external_id: external_id,
          account: account,
          email: email,
          host: host
        })

      # These all work
      assert %Customer{id: ^customer_id} = Customers.find_by_external_id(123, account.id)

      assert %Customer{id: ^customer_id} =
               Customers.find_by_external_id(123, account.id, %{"email" => email})

      assert %Customer{id: ^customer_id} =
               Customers.find_by_external_id(123, account.id, %{"email" => email, "host" => host})

      # These all should not work
      refute Customers.find_by_external_id(123, account.id, %{"email" => "other@test.com"})

      refute Customers.find_by_external_id(123, account.id, %{
               "email" => email,
               "host" => "other.host.com"
             })
    end

    test "find_or_create_by_email/3 finds the matching customer", %{account: account} do
      email = "test@test.com"
      %{id: customer_id} = insert(:customer, %{email: email, account: account})

      assert {:ok, %Customer{id: ^customer_id}} =
               Customers.find_or_create_by_email(email, account.id)
    end

    test "find_or_create_by_email/3 creates a new customer if necessary", %{account: account} do
      email = "test@test.com"
      %{id: customer_id} = insert(:customer, %{email: "other@test.com", account: account})

      assert {:ok, %Customer{} = customer} = Customers.find_or_create_by_email(email, account.id)
      assert customer.id != customer_id
      assert customer.email == email
    end

    test "find_or_create_by_email/3 creates a new customer with additional params", %{
      account: account
    } do
      email = "test@test.com"
      %{id: customer_id} = insert(:customer, %{email: "other@test.com", account: account})

      assert {:ok, %Customer{} = customer} =
               Customers.find_or_create_by_email(email, account.id, %{name: "New Customer"})

      assert customer.id != customer_id
      assert customer.email == email
      assert customer.name == "New Customer"
    end

    test "find_or_create_by_email/3 returns an :error tuple if email is nil", %{
      account: account
    } do
      assert {:error, _error} = Customers.find_or_create_by_email(nil, account.id)

      assert {:error, _error} =
               Customers.find_or_create_by_email(nil, account.id, %{name: "New Customer"})
    end

    test "create_or_update_by_email/3 finds the matching customer", %{account: account} do
      email = "test@test.com"
      %{id: customer_id} = insert(:customer, %{email: email, account: account})

      assert {:ok, %Customer{id: ^customer_id}} =
               Customers.create_or_update_by_email(email, account.id)
    end

    test "create_or_update_by_email/3 updates the matching customer", %{account: account} do
      email = "test@test.com"
      name = "Test User"
      %{id: customer_id} = insert(:customer, %{email: email, account: account})

      assert {:ok, %Customer{id: ^customer_id, name: ^name}} =
               Customers.create_or_update_by_email(email, account.id, %{name: name})
    end

    test "create_or_update_by_email/3 creates a new customer if necessary", %{account: account} do
      email = "test@test.com"
      %{id: customer_id} = insert(:customer, %{email: "other@test.com", account: account})

      assert {:ok, %Customer{} = customer} =
               Customers.create_or_update_by_email(email, account.id)

      assert customer.id != customer_id
      assert customer.email == email
    end

    test "create_or_update_by_email/3 creates a new customer with additional params", %{
      account: account
    } do
      email = "test@test.com"
      %{id: customer_id} = insert(:customer, %{email: "other@test.com", account: account})

      assert {:ok, %Customer{} = customer} =
               Customers.create_or_update_by_email(email, account.id, %{name: "New Customer"})

      assert customer.id != customer_id
      assert customer.email == email
      assert customer.name == "New Customer"
    end

    test "create_or_update_by_email/3 returns an :error tuple if email is nil", %{
      account: account
    } do
      assert {:error, _error} = Customers.create_or_update_by_email(nil, account.id)

      assert {:error, _error} =
               Customers.create_or_update_by_email(nil, account.id, %{name: "New Customer"})
    end

    test "create_or_update_by_external_id/3 finds the matching customer", %{account: account} do
      external_id = "a0xxxxxxx1yz"
      %{id: customer_id} = insert(:customer, %{external_id: external_id, account: account})

      assert {:ok, %Customer{id: ^customer_id}} =
               Customers.create_or_update_by_external_id(external_id, account.id)
    end

    test "create_or_update_by_external_id/3 updates the matching customer", %{account: account} do
      external_id = "a0xxxxxxx1yz"
      name = "Test User"
      %{id: customer_id} = insert(:customer, %{external_id: external_id, account: account})

      assert {:ok, %Customer{id: ^customer_id, name: ^name}} =
               Customers.create_or_update_by_external_id(external_id, account.id, %{name: name})
    end

    test "create_or_update_by_external_id/3 creates a new customer if necessary", %{
      account: account
    } do
      external_id = "a0xxxxxxx1yz"
      %{id: customer_id} = insert(:customer, %{external_id: "other@test.com", account: account})

      assert {:ok, %Customer{} = customer} =
               Customers.create_or_update_by_external_id(external_id, account.id)

      assert customer.id != customer_id
      assert customer.external_id == external_id
    end

    test "create_or_update_by_external_id/3 creates a new customer with additional params", %{
      account: account
    } do
      external_id = "a0xxxxxxx1yz"
      %{id: customer_id} = insert(:customer, %{email: "other@test.com", account: account})

      assert {:ok, %Customer{} = customer} =
               Customers.create_or_update_by_external_id(external_id, account.id, %{
                 name: "New Customer"
               })

      assert customer.id != customer_id
      assert customer.external_id == external_id
      assert customer.name == "New Customer"
    end

    test "create_or_update_by_external_id/3 returns an :error tuple if email is nil", %{
      account: account
    } do
      assert {:error, _error} = Customers.create_or_update_by_external_id(nil, account.id)

      assert {:error, _error} =
               Customers.create_or_update_by_external_id(nil, account.id, %{name: "New Customer"})
    end
  end
end
