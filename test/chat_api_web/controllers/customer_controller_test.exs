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

  def fixture(:customer) do
    {:ok, customer} = Customers.create_customer(valid_create_attrs())
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
  end

  defp create_customer(_) do
    customer = fixture(:customer)
    %{customer: customer}
  end
end
