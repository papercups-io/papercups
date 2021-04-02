defmodule ChatApiWeb.TwilioControllerTest do
  use ChatApiWeb.ConnCase

  import Mock
  import ChatApi.Factory
  import ExUnit.CaptureLog

  @customer_phone_number "+1231231234"
  @twilio_phone_number "+1235556666"

  @valid_account_sid "VALID_123"
  @invalid_account_sid "INVALID_456"

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "webhook" do
    test "returns 200 when message is successfully created", %{
      authed_conn: authed_conn,
      account: account
    } do
      _authorization =
        insert(:twilio_authorization,
          account: account,
          twilio_account_sid: @valid_account_sid,
          from_phone_number: @twilio_phone_number
        )

      _customer = insert(:customer, account: account, phone: @customer_phone_number)

      with_mock ChatApi.Messages.Notification,
        notify: fn msg, _ -> msg end,
        broadcast_to_customer!: fn msg -> msg end,
        broadcast_to_admin!: fn msg -> msg end do
        conn =
          post(authed_conn, Routes.twilio_path(authed_conn, :webhook), %{
            "AccountSid" => @valid_account_sid,
            "To" => @twilio_phone_number,
            "From" => @customer_phone_number,
            "Body" => "Test message"
          })

        assert response(conn, 200)
      end
    end

    test "returns 200 when Twilio account is not found",
         %{authed_conn: authed_conn, account: account} do
      _authorization =
        insert(:twilio_authorization,
          account: account,
          twilio_account_sid: @invalid_account_sid,
          from_phone_number: @twilio_phone_number
        )

      _customer = insert(:customer, account: account, phone: @customer_phone_number)

      assert capture_log(fn ->
               conn =
                 post(authed_conn, Routes.twilio_path(authed_conn, :webhook), %{
                   "AccountSid" => @valid_account_sid,
                   "To" => @twilio_phone_number,
                   "From" => @customer_phone_number,
                   "Body" => "Test message"
                 })

               assert response(conn, 200)
             end) =~ "Twilio account not found"
    end

    test "returns 500 when an unexpected error occurs",
         %{authed_conn: authed_conn, account: account} do
      _authorization =
        insert(:twilio_authorization,
          account: account,
          twilio_account_sid: @valid_account_sid,
          from_phone_number: @twilio_phone_number
        )

      with_mock ChatApi.Conversations,
        find_or_create_by_customer: fn _, _, _ ->
          {:error, %Ecto.Changeset{}}
        end do
        assert capture_log(fn ->
                 conn =
                   post(authed_conn, Routes.twilio_path(authed_conn, :webhook), %{
                     "AccountSid" => @valid_account_sid,
                     "To" => @twilio_phone_number,
                     "From" => @customer_phone_number,
                     "Body" => "Test message"
                   })

                 assert response(conn, 500)
               end)
      end
    end
  end
end
