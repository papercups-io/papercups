defmodule ChatApi.EmailsTest do
  use ChatApi.DataCase
  import ChatApi.Factory
  alias ChatApi.Emails

  describe "emails" do
    setup do
      account = insert(:account)
      conversation = insert(:conversation, account: account)

      {:ok, account: account, conversation: conversation}
    end

    test "new_message_alert/2 generates a new message alert for a message from an anonymous customer",
         %{
           account: account,
           conversation: conversation
         } do
      customer = insert(:customer, account: account, name: nil, email: nil)
      message = insert(:message, account: account, conversation: conversation, customer: customer)
      conversation_id = conversation.id
      recipient = "test@test.com"
      email = Emails.Email.new_message_alert(recipient, message)

      assert email.subject ==
               "A customer has sent you a message (conversation #{conversation_id})"

      assert email.text_body == "New message from an anonymous user: some message body"

      assert email.html_body ==
               "New message from an anonymous user:<br /><b>some message body</b><br /><br /><a href=\"https:///conversations/#{
                 conversation_id
               }\">View in dashboard</a>"
    end

    test "new_message_alert/2 generates a new message alert for a message from a customer with a name",
         %{
           account: account,
           conversation: conversation
         } do
      customer = insert(:customer, account: account, name: "Test User", email: nil)
      message = insert(:message, account: account, conversation: conversation, customer: customer)
      conversation_id = conversation.id
      recipient = "test@test.com"
      email = Emails.Email.new_message_alert(recipient, message)

      assert email.subject ==
               "Test User has sent you a message"

      assert email.text_body == "New message from Test User: some message body"

      assert email.html_body ==
               "New message from Test User:<br /><b>some message body</b><br /><br /><a href=\"https:///conversations/#{
                 conversation_id
               }\">View in dashboard</a>"
    end

    test "new_message_alert/2 generates a new message alert for a message from a customer with an email",
         %{
           account: account,
           conversation: conversation
         } do
      customer = insert(:customer, account: account, email: "customer@customer.com", name: nil)
      message = insert(:message, account: account, conversation: conversation, customer: customer)
      conversation_id = conversation.id
      recipient = "test@test.com"
      email = Emails.Email.new_message_alert(recipient, message)

      assert email.subject ==
               "customer@customer.com has sent you a message"

      assert email.text_body == "New message from customer@customer.com: some message body"

      assert email.html_body ==
               "New message from customer@customer.com:<br /><b>some message body</b><br /><br /><a href=\"https:///conversations/#{
                 conversation_id
               }\">View in dashboard</a>"
    end

    test "new_message_alert/2 generates a new message alert for a message from a customer with both a name and an email",
         %{
           account: account,
           conversation: conversation
         } do
      customer =
        insert(:customer, account: account, email: "customer@customer.com", name: "Test User")

      message = insert(:message, account: account, conversation: conversation, customer: customer)
      conversation_id = conversation.id
      recipient = "test@test.com"
      email = Emails.Email.new_message_alert(recipient, message)

      assert email.subject ==
               "Test User (customer@customer.com) has sent you a message"

      assert email.text_body ==
               "New message from Test User (customer@customer.com): some message body"

      assert email.html_body ==
               "New message from Test User (customer@customer.com):<br /><b>some message body</b><br /><br /><a href=\"https:///conversations/#{
                 conversation_id
               }\">View in dashboard</a>"
    end
  end
end
