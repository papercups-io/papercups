defmodule ChatApi.TwilioTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  import Mock

  alias ChatApi.Twilio

  @valid_phone "555-555-5555"
  @invalid_phone "555-5555"

  describe "Slack.Notification" do
    setup do
      account = insert(:account)
      customer = insert(:customer, account: account)
      authorization = insert(:twilio_authorization, account: account)
      user = insert(:user, account: account, email: "user@user.com")

      {:ok, account: account, customer: customer, user: user, authorization: authorization}
    end

    test "Notification.notify_sms/2 errors when not an sms conversation", %{
      account: account,
      customer: customer
    } do
      conversation = insert(:conversation, account: account, customer: customer, source: "email")
      message = insert(:message, conversation: conversation, customer: customer)

      with_mock ChatApi.Twilio.Client,
        validate_phone: fn num, _ ->
          validate_phone_mock(num)
        end do
        assert {:error, :not_sms_conversation} = Twilio.Notification.notify_sms(message)
        assert_not_called(Twilio.Client.send_message(:_, :_))
      end
    end

    test "Notification.notify_sms/2 errors when customer has invalid phone number", %{
      account: account
    } do
      customer = insert(:customer, account: account, phone: @invalid_phone)
      conversation = insert(:conversation, account: account, customer: customer, source: "sms")
      message = insert(:message, conversation: conversation, customer: customer, account: account)

      with_mock Twilio.Client,
        send_message: fn _, _ ->
          {:ok, :_}
        end,
        validate_phone: fn num, _ ->
          validate_phone_mock(num)
        end do
        assert {:error, :bad_number} = Twilio.Notification.notify_sms(message)
        assert_not_called(Twilio.Client.send_message(:_, :_))
      end
    end

    test "Notification.notify_sms/2 sends a reply notification", %{
      account: account
    } do
      customer = insert(:customer, account: account, phone: @valid_phone)
      conversation = insert(:conversation, account: account, customer: customer, source: "sms")
      message = insert(:message, account: account, conversation: conversation, customer: customer)
      insert(:twilio_authorization, account: account, from_phone_number: @valid_phone)

      with_mock Twilio.Client,
        send_message: fn _, _ ->
          {:ok, :_}
        end,
        validate_phone: fn num, _ ->
          validate_phone_mock(num)
        end do
        assert {:ok, _} = Twilio.Notification.notify_sms(message)
        assert_called(Twilio.Client.send_message(:_, :_))
      end
    end
  end

  defp validate_phone_mock(@valid_phone), do: {:ok, @valid_phone}
  defp validate_phone_mock(@invalid_phone), do: {:error, :bad_number}
end
