defmodule ChatApiWeb.TwilioControllerTest do
  use ChatApiWeb.ConnCase

  import Mock
  import ChatApi.Factory

  alias ChatApi.Twilio
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages
  alias ChatApi.Messages.Message
  alias ChatApi.Conversations
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Twilio.TwilioAuthorization

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "webhook" do
    @request_body %{
      "AccountSid" => "1234",
      "To" => "1234",
      "From" => "1234",
      "Body" => "body"
    }

    test "returns 200 when message is successfuly created",
         %{authed_conn: authed_conn} do
      with_mocks([
        {
          Twilio,
          [],
          [
            find_twilio_authorization: fn _ ->
              %TwilioAuthorization{account_id: 1}
            end
          ]
        },
        {
          Conversations,
          [],
          [
            find_or_create_customer_and_conversation: fn _, __ ->
              {:ok, %Customer{id: 1}, %Conversation{id: 1}}
            end
          ]
        },
        {
          Messages,
          [],
          create_message: fn _ -> {:ok, %Message{id: 1}} end
        }
      ]) do
        conn = post(authed_conn, Routes.twilio_path(authed_conn, :webhook), @request_body)

        assert response(conn, 200)
      end
    end

    test "returns 200 when twilio account is not found",
         %{authed_conn: authed_conn} do
      with_mocks([
        {
          Twilio,
          [],
          [
            find_twilio_authorization: fn _ -> nil end
          ]
        }
      ]) do
        conn = post(authed_conn, Routes.twilio_path(authed_conn, :webhook), @request_body)

        assert response(conn, 200)
      end
    end

    test "returns 500 when unexpected error occurs",
         %{authed_conn: authed_conn} do
      with_mocks([
        {
          Twilio,
          [],
          [
            find_twilio_authorization: fn _ ->
              %TwilioAuthorization{account_id: 1}
            end
          ]
        },
        {
          Conversations,
          [],
          [
            find_or_create_customer_and_conversation: fn _, __ ->
              {:error, %Ecto.Changeset{}}
            end
          ]
        }
      ]) do
        conn = post(authed_conn, Routes.twilio_path(authed_conn, :webhook), @request_body)

        assert response(conn, 500)
      end
    end
  end
end
