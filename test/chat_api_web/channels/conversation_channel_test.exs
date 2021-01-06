defmodule ChatApiWeb.ConversationChannelTest do
  use ChatApiWeb.ChannelCase

  import ChatApi.Factory

  setup do
    account = insert(:account)
    customer = insert(:customer, account: account)
    conversation = insert(:conversation, account: account, customer: customer)

    {:ok, _, socket} =
      ChatApiWeb.UserSocket
      |> socket("user_id", %{some: :assign, customer_id: customer.id, conversation: conversation})
      |> subscribe_and_join(ChatApiWeb.ConversationChannel, "conversation:lobby")

    %{socket: socket, account: account}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to conversation:lobby", %{socket: socket, account: account} do
    msg = %{body: "Hello world!", account_id: account.id}
    push(socket, "shout", msg)
    assert_broadcast "shout", _msg
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end

  test "should handle typing event", %{socket: socket} do
    push(socket, "message:typing", %{})
    customer = socket.assigns.customer_id |> ChatApi.Customers.get_customer!()
    name = customer.name
    email = customer.email
    id = customer.id
    conversation_id = socket.assigns.conversation.id

    assert_broadcast "message:other_typing", %{
      customer: %{id: ^id, name: ^name, email: ^email, kind: "customer"},
      conversation_id: ^conversation_id
    }
  end
end
