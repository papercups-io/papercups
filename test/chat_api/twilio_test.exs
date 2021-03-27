defmodule ChatApi.TwilioTest do
  use ChatApi.DataCase, async: true
  import ChatApi.Factory
  alias ChatApi.Twilio

  test "find_or_create_customer_and_conversation/2 returns customer and new conversation when customer exists" do
    account = insert(:account)
    customer = insert(:customer, account: account)

    {:ok, found_customer, found_conversation} =
      Twilio.find_or_create_customer_and_conversation(account.id, customer.phone)

    assert customer.id == found_customer.id

    assert customer.id == found_conversation.customer_id
    assert "sms" == found_conversation.source
  end

  test "find_or_create_customer_and_conversation/2 returns new customer and conversation when customer doesn't exist" do
    account = insert(:account)
    phone_number = "+18675309"

    {:ok, found_customer, found_conversation} =
      Twilio.find_or_create_customer_and_conversation(account.id, phone_number)

    assert phone_number == found_customer.phone
    assert account.id == found_customer.account_id
    assert account.id == found_conversation.account_id
  end

  test "find_or_create_customer_and_conversation/2 returns latest conversations when multiple conversations exist" do
    account = insert(:account)
    customer = insert(:customer, account: account)

    insert(:conversation,
      account: account,
      customer: customer,
      inserted_at: ~N[2020-12-01 00:00:00],
      source: "sms"
    )

    insert(:conversation,
      account: account,
      customer: customer,
      inserted_at: ~N[2020-12-01 00:01:00],
      source: "sms"
    )

    latest_conversation =
      insert(:conversation,
        account: account,
        customer: customer,
        inserted_at: ~N[2020-12-01 00:02:00],
        source: "sms"
      )

    {:ok, found_customer, found_conversation} =
      Twilio.find_or_create_customer_and_conversation(account.id, "+18675309")

    assert latest_conversation.id == found_conversation.id
    assert customer.id == found_customer.id
  end
end
