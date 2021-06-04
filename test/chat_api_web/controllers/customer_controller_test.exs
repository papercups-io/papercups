defmodule ChatApiWeb.CustomerControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.Customers.Customer

  @update_attrs %{
    first_seen: ~D[2020-01-01],
    name: "Test User",
    email: "user@test.com",
    phone: "+16501235555",
    time_zone: "America/New_York"
  }

  @invalid_attrs %{
    last_seen_at: 3
  }

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    customer = insert(:customer, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account, customer: customer}
  end

  describe "index" do
    test "lists all customers", %{authed_conn: authed_conn, customer: customer} do
      resp = get(authed_conn, Routes.customer_path(authed_conn, :index))
      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [customer.id]
    end

    test "lists all customers by company", %{authed_conn: authed_conn, account: account} do
      company = insert(:company, account: account)
      new_customer = insert(:customer, account: account, company: company)

      resp =
        get(authed_conn, Routes.customer_path(authed_conn, :index, %{"company_id" => company.id}))

      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [new_customer.id]
    end

    test "lists all customers in csv format", %{authed_conn: authed_conn, customer: customer} do
      resp = get(authed_conn, Routes.customer_path(authed_conn, :index) <> "?format=csv")
      csv = response(resp, 200)

      assert is_binary(csv)
      [headers, row1] = String.split(csv, "\r\n")

      assert headers ==
               "id,name,email,created_at,updated_at,first_seen,last_seen_at,phone," <>
                 "external_id,host,pathname,current_url,browser,os,ip,time_zone"

      assert row1 ==
               "\"#{customer.id}\",\"#{customer.name}\",\"#{customer.email}\"," <>
                 "\"#{customer.inserted_at}\",\"#{customer.updated_at}\",\"#{customer.first_seen}\"," <>
                 "\"#{customer.last_seen_at}\",\"#{customer.phone}\",\"#{customer.external_id}\"," <>
                 "\"#{customer.host}\",\"#{customer.pathname}\",\"#{customer.current_url}\"," <>
                 "\"#{customer.browser}\",\"#{customer.os}\",\"#{customer.ip}\"," <>
                 "\"#{customer.time_zone}\""

      assert get_resp_header(resp, "content-type") == ["text/csv; charset=utf-8"]
    end
  end

  describe "create customer" do
    test "renders customer when data is valid", %{
      conn: conn,
      authed_conn: authed_conn,
      account: account
    } do
      resp =
        post(conn, Routes.customer_path(conn, :create),
          customer: params_for(:customer, account: account)
        )

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.customer_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "object" => "customer"
             } = json_response(resp, 200)["data"]
    end

    test "ensures external_id is a string", %{conn: conn, account: account} do
      customer = params_for(:customer, account: account, external_id: 123)
      resp = post(conn, Routes.customer_path(conn, :create), customer: customer)

      assert %{"external_id" => "123"} = json_response(resp, 201)["data"]
    end

    test "truncates current_url if it is too long", %{conn: conn, account: account} do
      current_url =
        "http://example.com/login?next=/insights%3Finsight%3DTRENDS%26interval%3Dday%26events%3D%255B%257B%2522id%2522%253A%2522%2524pageview%2522%252C%2522name%2522%253A%2522%2524pageview%2522%252C%2522type%2522%253A%2522events%2522%252C%2522order%2522%253A0%252C%2522math%2522%253A%2522total%2522%257D%255D%26display%3DActionsTable%26actions%3D%255B%255D%26new_entity%3D%255B%255D%26breakdown%3D%2524browser%26breakdown_type%3Devent%26properties%3D%255B%255D"

      customer = params_for(:customer, account: account, current_url: current_url)
      resp = post(conn, Routes.customer_path(conn, :create), customer: customer)

      assert %{"current_url" => truncated} = json_response(resp, 201)["data"]
      assert String.length(truncated) <= 255
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.customer_path(conn, :create), customer: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update customer" do
    test "renders customer when data is valid",
         %{authed_conn: authed_conn, customer: %Customer{id: id} = customer} do
      resp =
        put(authed_conn, Routes.customer_path(authed_conn, :update, customer),
          customer: @update_attrs
        )

      assert %{"id" => ^id} = json_response(resp, 200)["data"]

      resp = get(authed_conn, Routes.customer_path(authed_conn, :show, id))

      assert %{
               "id" => _id
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn, customer: customer} do
      resp =
        put(authed_conn, Routes.customer_path(authed_conn, :update, customer),
          customer: @invalid_attrs
        )

      assert json_response(resp, 422)["errors"] != %{}
    end
  end

  describe "delete customer" do
    test "deletes chosen customer", %{authed_conn: authed_conn, customer: customer} do
      resp =
        delete(
          authed_conn,
          Routes.customer_path(authed_conn, :delete, customer)
        )

      assert response(resp, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.customer_path(authed_conn, :show, customer))
      end)
    end
  end

  # TODO: add some more tests!
  describe "adding/removing tags" do
    test "adds a tag", %{authed_conn: authed_conn, customer: customer, account: account} do
      tag = insert(:tag, account: account, name: "Test Tag")

      resp =
        post(authed_conn, Routes.customer_path(authed_conn, :add_tag, customer), tag_id: tag.id)

      assert json_response(resp, 200)["data"]["ok"]
      resp = get(authed_conn, Routes.customer_path(authed_conn, :show, customer.id))

      assert %{
               "tags" => tags
             } = json_response(resp, 200)["data"]

      assert [%{"name" => "Test Tag"}] = tags
    end

    test "removes a tag", %{authed_conn: authed_conn, customer: customer, account: account} do
      tag = insert(:tag, account: account, name: "Test Tag")

      resp =
        post(
          authed_conn,
          Routes.customer_path(authed_conn, :add_tag, customer),
          tag_id: tag.id
        )

      assert json_response(resp, 200)["data"]["ok"]

      resp =
        delete(
          authed_conn,
          Routes.customer_path(authed_conn, :remove_tag, customer, tag)
        )

      assert json_response(resp, 200)["data"]["ok"]
    end
  end

  describe "update customer metadata" do
    test "renders customer when data is valid",
         %{
           conn: conn,
           authed_conn: authed_conn,
           customer: %Customer{id: id} = customer
         } do
      resp =
        put(conn, Routes.customer_path(conn, :update_metadata, customer), metadata: @update_attrs)

      assert %{"id" => ^id} = json_response(resp, 200)["data"]

      resp = get(authed_conn, Routes.customer_path(authed_conn, :show, id))

      assert %{
               "email" => email,
               "name" => name,
               "time_zone" => time_zone
             } = json_response(resp, 200)["data"]

      assert email == @update_attrs.email
      assert name == @update_attrs.name
      assert time_zone == @update_attrs.time_zone
    end

    test "ensures external_id is a string",
         %{conn: conn, customer: %Customer{id: id} = customer} do
      resp =
        put(conn, Routes.customer_path(conn, :update_metadata, customer),
          metadata: %{external_id: 123}
        )

      assert %{
               "id" => ^id,
               "external_id" => "123"
             } = json_response(resp, 200)["data"]
    end
  end

  describe "identifies a customer by external_id" do
    test "finds the correct customer", %{conn: conn, account: account} do
      external_id = "cus_123"
      email = "customer@test.com"
      host = "app.test.com"

      customer =
        insert(:customer, account: account, external_id: external_id, email: email, host: host)

      customer_id = customer.id

      resp =
        get(conn, Routes.customer_path(conn, :identify),
          account_id: account.id,
          external_id: external_id,
          email: email,
          host: host
        )

      assert %{
               "customer_id" => ^customer_id
             } = json_response(resp, 200)["data"]
    end

    test "ignoring nil/null filters", %{conn: conn, account: account} do
      external_id = "cus_123"
      email = "customer@test.com"
      host = "app.test.com"

      customer =
        insert(:customer, account: account, external_id: external_id, email: email, host: host)

      customer_id = customer.id

      resp =
        get(conn, Routes.customer_path(conn, :identify),
          account_id: account.id,
          external_id: external_id,
          email: email,
          host: nil
        )

      assert %{
               "customer_id" => ^customer_id
             } = json_response(resp, 200)["data"]
    end

    test "returns nil if no match is found", %{conn: conn, account: account} do
      external_id = "cus_123"
      email = "test@test.com"
      _customer = insert(:customer, account: account, external_id: external_id, email: email)

      resp =
        get(conn, Routes.customer_path(conn, :identify),
          account_id: account.id,
          external_id: "invalid"
        )

      assert %{
               "customer_id" => nil
             } = json_response(resp, 200)["data"]

      resp =
        get(conn, Routes.customer_path(conn, :identify),
          account_id: account.id,
          external_id: external_id,
          email: "unknown@test.com"
        )

      assert %{
               "customer_id" => nil
             } = json_response(resp, 200)["data"]
    end

    test "returns the most recent match if multiple exist", %{conn: conn} do
      external_id = "cus_123"
      acc_1 = insert(:account)
      insert(:customer, account: acc_1, external_id: external_id)

      acc_2 = insert(:account)
      insert(:customer, account: acc_2, external_id: external_id)

      acc_3 = insert(:account)
      customer_c = insert(:customer, account: acc_3, external_id: external_id)

      %{id: customer_c_id, account_id: account_id} = customer_c

      resp =
        get(conn, Routes.customer_path(conn, :identify),
          account_id: account_id,
          external_id: external_id
        )

      assert %{
               "customer_id" => ^customer_c_id
             } = json_response(resp, 200)["data"]
    end
  end

  describe "authorization is required" do
    test "for :show route", %{authed_conn: authed_conn} do
      customer = unauthorized_customer()
      resp = get(authed_conn, Routes.customer_path(authed_conn, :show, customer))

      assert json_response(resp, 404)["error"]["message"] == "Not found"
    end

    test "for :update route", %{authed_conn: authed_conn} do
      customer = unauthorized_customer()

      resp =
        put(authed_conn, Routes.customer_path(authed_conn, :delete, customer),
          customer: @update_attrs
        )

      assert json_response(resp, 404)["error"]["message"] == "Not found"
    end

    test "for :delete route", %{authed_conn: authed_conn} do
      customer = unauthorized_customer()
      resp = delete(authed_conn, Routes.customer_path(authed_conn, :delete, customer))

      assert json_response(resp, 404)["error"]["message"] == "Not found"
    end

    defp unauthorized_customer() do
      account = insert(:account)

      insert(:customer, account: account)
    end
  end
end
