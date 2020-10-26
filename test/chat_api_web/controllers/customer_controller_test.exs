defmodule ChatApiWeb.CustomerControllerTest do
  use ChatApiWeb.ConnCase, async: true

  alias ChatApi.Customers.Customer

  @create_attrs %{
    first_seen: ~D[2020-01-01],
    last_seen: ~D[2020-01-01]
  }
  @update_attrs %{
    first_seen: ~D[2020-01-01],
    last_seen: ~D[2020-01-02],
    name: "Test User",
    email: "user@test.com",
    phone: "+16501235555",
    time_zone: "America/New_York"
  }

  @invalid_attrs %{
    last_seen: 3
  }

  def valid_create_attrs(account) do
    Enum.into(@create_attrs, %{account_id: account.id})
  end

  setup %{conn: conn} do
    account = account_fixture()
    user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])
    customer = customer_fixture(account)

    {:ok, conn: conn, authed_conn: authed_conn, account: account, customer: customer}
  end

  describe "index" do
    test "lists all customers", %{authed_conn: authed_conn, customer: customer} do
      resp = get(authed_conn, Routes.customer_path(authed_conn, :index))
      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [customer.id]
    end

    test "lists all customers in csv format", %{authed_conn: authed_conn, customer: customer} do
      resp = get(authed_conn, Routes.customer_path(authed_conn, :index) <> "?format=csv")
      csv = response(resp, 200)

      assert is_binary(csv)
      [headers, row1] = String.split(csv, "\r\n")

      assert headers ==
               "id,name,email,created_at,updated_at,first_seen,last_seen,phone," <>
                 "external_id,host,pathname,current_url,browser,os,ip,time_zone"

      assert row1 ==
               "\"#{customer.id}\",\"#{customer.name}\",\"#{customer.email}\"," <>
                 "\"#{customer.inserted_at}\",\"#{customer.updated_at}\",\"#{customer.first_seen}\"," <>
                 "\"#{customer.last_seen}\",\"#{customer.phone}\",\"#{customer.external_id}\"," <>
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
        post(conn, Routes.customer_path(conn, :create), customer: valid_create_attrs(account))

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.customer_path(authed_conn, :show, id))

      assert %{
               "id" => id
             } = json_response(resp, 200)["data"]
    end

    test "ensures external_id is a string", %{
      conn: conn,
      account: account
    } do
      customer = Map.merge(valid_create_attrs(account), %{external_id: 123})
      resp = post(conn, Routes.customer_path(conn, :create), customer: customer)

      assert %{"external_id" => "123"} = json_response(resp, 201)["data"]
    end

    test "truncates current_url if it is too long", %{
      conn: conn,
      account: account
    } do
      current_url =
        "http://example.com/login?next=/insights%3Finsight%3DTRENDS%26interval%3Dday%26events%3D%255B%257B%2522id%2522%253A%2522%2524pageview%2522%252C%2522name%2522%253A%2522%2524pageview%2522%252C%2522type%2522%253A%2522events%2522%252C%2522order%2522%253A0%252C%2522math%2522%253A%2522total%2522%257D%255D%26display%3DActionsTable%26actions%3D%255B%255D%26new_entity%3D%255B%255D%26breakdown%3D%2524browser%26breakdown_type%3Devent%26properties%3D%255B%255D"

      customer = Map.merge(valid_create_attrs(account), %{current_url: current_url})
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
    test "renders customer when data is valid", %{
      authed_conn: authed_conn,
      customer: %Customer{id: id} = customer
    } do
      resp =
        put(authed_conn, Routes.customer_path(authed_conn, :update, customer),
          customer: @update_attrs
        )

      assert %{"id" => ^id} = json_response(resp, 200)["data"]

      resp = get(authed_conn, Routes.customer_path(authed_conn, :show, id))

      assert %{
               "id" => id
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
      resp = delete(authed_conn, Routes.customer_path(authed_conn, :delete, customer))
      assert response(resp, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.customer_path(authed_conn, :show, customer))
      end)
    end
  end

  # TODO: add some more tests!
  describe "adding/removing tags" do
    test "adds a tag", %{authed_conn: authed_conn, customer: customer, account: account} do
      tag = tag_fixture(account, %{name: "Test Tag"})

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
      tag = tag_fixture(account, %{name: "Test Tag"})

      resp =
        post(authed_conn, Routes.customer_path(authed_conn, :add_tag, customer), tag_id: tag.id)

      assert json_response(resp, 200)["data"]["ok"]
      resp = delete(authed_conn, Routes.customer_path(authed_conn, :remove_tag, customer, tag))
      assert json_response(resp, 200)["data"]["ok"]
    end
  end

  describe "update customer metadata" do
    test "renders customer when data is valid", %{
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

    test "ensures external_id is a string", %{
      conn: conn,
      customer: %Customer{id: id} = customer
    } do
      resp =
        put(conn, Routes.customer_path(conn, :update_metadata, customer),
          metadata: %{external_id: 123}
        )

      assert %{"id" => ^id, "external_id" => "123"} = json_response(resp, 200)["data"]
    end
  end

  describe "identifies a customer by external_id" do
    test "finds the correct customer", %{
      conn: conn,
      account: account
    } do
      external_id = "cus_123"
      customer = customer_fixture(account, %{external_id: external_id})
      %{id: customer_id, account_id: account_id} = customer

      resp =
        get(conn, Routes.customer_path(conn, :identify),
          account_id: account_id,
          external_id: external_id
        )

      assert %{
               "customer_id" => ^customer_id
             } = json_response(resp, 200)["data"]
    end

    test "returns nil if no match is found", %{
      conn: conn,
      account: account
    } do
      customer = customer_fixture(account, %{external_id: "cus_123"})
      %{id: _customer_id, account_id: account_id} = customer

      resp =
        get(conn, Routes.customer_path(conn, :identify),
          account_id: account_id,
          external_id: "invalid"
        )

      assert %{
               "customer_id" => nil
             } = json_response(resp, 200)["data"]
    end

    test "returns the most recent match if multiple exist", %{
      conn: conn
    } do
      external_id = "cus_123"
      acc_1 = account_fixture()
      _customer_a = customer_fixture(acc_1, %{external_id: external_id})

      acc_2 = account_fixture()
      _customer_b = customer_fixture(acc_2, %{external_id: external_id})

      acc_3 = account_fixture()
      customer_c = customer_fixture(acc_3, %{external_id: external_id})

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
end
