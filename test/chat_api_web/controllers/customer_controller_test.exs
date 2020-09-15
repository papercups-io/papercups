defmodule ChatApiWeb.CustomerControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.Customers
  alias ChatApi.Customers.Customer
  alias ChatApi.Accounts

  @create_attrs %{
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
    last_seen: 3
  }

  def valid_create_attrs do
    account = fixture(:account)

    Enum.into(@create_attrs, %{account_id: account.id})
  end

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    account
  end

  def fixture(:customer, attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> Enum.into(valid_create_attrs())
      |> Customers.create_customer()

    customer
  end

  setup %{conn: conn} do
    account = fixture(:account)
    user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn}
  end

  describe "index" do
    test "lists all customers", %{authed_conn: authed_conn} do
      resp = get(authed_conn, Routes.customer_path(authed_conn, :index))
      assert json_response(resp, 200)["data"] == []
    end
  end

  describe "create customer" do
    test "renders customer when data is valid", %{conn: conn, authed_conn: authed_conn} do
      resp = post(conn, Routes.customer_path(conn, :create), customer: valid_create_attrs())

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.customer_path(authed_conn, :show, id))

      assert %{
               "id" => id
             } = json_response(resp, 200)["data"]
    end

    test "ensures external_id is a string", %{
      conn: conn
    } do
      customer = Map.merge(valid_create_attrs(), %{external_id: 123})
      resp = post(conn, Routes.customer_path(conn, :create), customer: customer)

      assert %{"external_id" => "123"} = json_response(resp, 201)["data"]
    end

    test "truncates current_url if it is too long", %{
      conn: conn
    } do
      current_url =
        "http://example.com/login?next=/insights%3Finsight%3DTRENDS%26interval%3Dday%26events%3D%255B%257B%2522id%2522%253A%2522%2524pageview%2522%252C%2522name%2522%253A%2522%2524pageview%2522%252C%2522type%2522%253A%2522events%2522%252C%2522order%2522%253A0%252C%2522math%2522%253A%2522total%2522%257D%255D%26display%3DActionsTable%26actions%3D%255B%255D%26new_entity%3D%255B%255D%26breakdown%3D%2524browser%26breakdown_type%3Devent%26properties%3D%255B%255D"

      customer = Map.merge(valid_create_attrs(), %{current_url: current_url})
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
    setup [:create_customer]

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
    setup [:create_customer]

    test "deletes chosen customer", %{authed_conn: authed_conn, customer: customer} do
      resp = delete(authed_conn, Routes.customer_path(authed_conn, :delete, customer))
      assert response(resp, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.customer_path(authed_conn, :show, customer))
      end)
    end
  end

  describe "update customer metadata" do
    setup [:create_customer]

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
               "name" => name
             } = json_response(resp, 200)["data"]

      assert email == @update_attrs.email
      assert name == @update_attrs.name
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
      conn: conn
    } do
      external_id = "cus_123"
      customer = fixture(:customer, %{external_id: external_id})
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
      conn: conn
    } do
      customer = fixture(:customer, %{external_id: "cus_123"})
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
      _customer_a = fixture(:customer, %{external_id: external_id})
      _customer_b = fixture(:customer, %{external_id: external_id})
      customer_c = fixture(:customer, %{external_id: external_id})
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

  defp create_customer(_) do
    customer = fixture(:customer)
    %{customer: customer}
  end
end
