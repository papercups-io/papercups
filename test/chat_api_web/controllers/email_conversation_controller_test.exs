defmodule ChatApiWeb.CustomerControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.Customers

  setup %{conn: conn} do
    account = insert(:account)
    customer = insert(:customer, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    {:ok, conn: conn, account: account, customer: customer}
  end

  describe "create with an existing customer_id" do
    test "updates the existing customer, and creates a conversation and message", %{
      conn: conn,
      account: account,
      customer: customer
    } do
      new_email_address = "test@papercups.io"
      body = "email test body"
      assert customer.email !== new_email_address

      resp =
        post(conn, Routes.email_conversation_path(conn, :create),
          account_id: account.id,
          body: body,
          customer_id: customer.id,
          email_address: new_email_address
        )

      assert resp.status === 201

      updated_customer = Customers.get_customer!(customer.id, [:messages])
      assert updated_customer.email === new_email_address

      message = Enum.at(updated_customer.messages, 0)
      assert message.body === body
      assert message.subject === nil
    end

    test "includes the subject if provided", %{
      conn: conn,
      account: account,
      customer: customer
    } do
      subject = "hello!"

      resp =
        post(conn, Routes.email_conversation_path(conn, :create),
          account_id: account.id,
          body: "email test body",
          customer_id: customer.id,
          email_address: "test@papercups.io",
          subject: subject
        )

      assert resp.status === 201

      updated_customer = Customers.get_customer!(customer.id, [:messages])
      message = Enum.at(updated_customer.messages, 0)
      assert message.subject === subject
    end
  end

  describe "create without an existing customer_id" do
    test "creates a new customer, conversation, and message", %{
      conn: conn,
      account: account
    } do
      email_address = "test@papercups.io"
      body = "email test body"

      customer = Customers.find_by_email(email_address, account.id)
      assert customer === nil

      resp =
        post(conn, Routes.email_conversation_path(conn, :create),
          account_id: account.id,
          body: body,
          email_address: email_address
        )

      assert resp.status === 201

      customer = Customers.find_by_email(email_address, account.id, [:messages])
      assert customer !== nil
      assert customer.email === email_address

      message = Enum.at(customer.messages, 0)
      assert message.body === body
      assert message.subject === nil
    end

    test "includes the subject if provided", %{
      conn: conn,
      account: account
    } do
      email_address = "test@papercups.io"
      subject = "hello!"

      resp =
        post(conn, Routes.email_conversation_path(conn, :create),
          account_id: account.id,
          body: "email test body",
          email_address: email_address,
          subject: subject
        )

      assert resp.status === 201

      customer = Customers.find_by_email(email_address, account.id, [:messages])
      message = Enum.at(customer.messages, 0)
      assert message.subject === subject
    end
  end
end
