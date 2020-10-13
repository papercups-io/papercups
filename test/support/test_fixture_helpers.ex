defmodule ChatApi.TestFixtureHelpers do
  @moduledoc false
  alias ChatApi.{
    Repo,
    Accounts,
    Users,
    Customers,
    Conversations,
    SlackConversationThreads,
    EventSubscriptions,
    Messages,
    SlackAuthorizations,
    Tags,
    WidgetSettings,
    UserInvitations
  }

  @password "supersecret123"

  def account_fixture() do
    {:ok, account} =
      %{company_name: "Test Inc #{counter()}"}
      |> Accounts.create_account()

    account
    |> Repo.preload([[users: :profile], :widget_settings])
  end

  def user_fixture(%Accounts.Account{} = account, attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "testuser#{counter()}@example.com",
        account_id: account.id,
        password: @password,
        password_confirmation: @password
      })
      |> Users.create_user()

    user
    |> Repo.preload([:profile, :conversations, :account, :settings])
  end

  def user_invitation_fixture(%Accounts.Account{} = account, attrs \\ %{}) do
    {:ok, user_invitation} =
      attrs
      |> Enum.into(%{account_id: account.id})
      |> UserInvitations.create_user_invitation()

    user_invitation
  end

  def customer_fixture(%Accounts.Account{} = account, attrs \\ %{}) do
    {:ok, customer} =
      %{
        first_seen: ~D[2020-01-01],
        last_seen: ~D[2020-01-01],
        email: "test-#{counter()}@test.com",
        account_id: account.id
      }
      |> Enum.into(attrs)
      |> Customers.create_test_customer()

    customer |> Repo.preload([:tags])
  end

  def conversation_fixture(
        %Accounts.Account{} = account,
        %Customers.Customer{} = customer,
        attrs \\ %{}
      ) do
    {:ok, conversation} =
      %{
        status: "open",
        account_id: account.id,
        customer_id: customer.id
      }
      |> Enum.into(attrs)
      |> Conversations.create_test_conversation()

    conversation |> Repo.preload([:customer, :tags, messages: [user: :profile]])
  end

  def message_fixture(
        %Accounts.Account{} = account,
        %Conversations.Conversation{} = conversation,
        attrs \\ %{}
      ) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        body: "some message body",
        conversation_id: conversation.id,
        account_id: account.id
      })
      |> Messages.create_test_message()

    Messages.get_message!(message.id)
    |> Repo.preload([:conversation, :customer, [user: :profile]])
  end

  def tag_fixture(
        %Accounts.Account{} = account,
        attrs \\ %{}
      ) do
    {:ok, tag} =
      attrs
      |> Enum.into(%{
        name: "some tag name",
        account_id: account.id
      })
      |> Tags.create_tag()

    tag
  end

  def slack_conversation_thread_fixture(
        %Conversations.Conversation{} = conversation,
        attrs \\ %{}
      ) do
    {:ok, slack_conversation_thread} =
      attrs
      |> Enum.into(%{
        account_id: conversation.account_id,
        conversation_id: conversation.id,
        slack_thread_ts: "1234.56789#{counter()}",
        slack_channel: "bots"
      })
      |> SlackConversationThreads.create_slack_conversation_thread()

    slack_conversation_thread
  end

  def event_subscription_fixture(%Accounts.Account{} = account, attrs \\ %{}) do
    {:ok, event_subscription} =
      attrs
      |> Enum.into(%{
        scope: "some valid scope",
        # verified: true,
        webhook_url: "some valid webhook_url",
        account_id: account.id
      })
      |> EventSubscriptions.create_event_subscription()

    event_subscription
  end

  def widget_settings_fixture(%Accounts.Account{} = account) do
    WidgetSettings.get_settings_by_account(account.id)
  end

  def slack_authorization_fixture(%Accounts.Account{} = account, attrs \\ %{}) do
    {:ok, slack_authorization} =
      attrs
      |> Enum.into(%{
        access_token: "some access_token",
        app_id: "some app_id #{counter()}",
        authed_user_id: "some authed_user_id #{counter()}",
        bot_user_id: "some bot_user_id #{counter()}",
        channel: "some channel",
        channel_id: "some channel_id #{counter()}",
        configuration_url: "some configuration_url",
        scope: "some scope",
        team_id: "some team_id #{counter()}",
        team_name: "some team_name #{counter()}",
        token_type: "some token_type",
        webhook_url: "some webhook_url",
        account_id: account.id
      })
      |> SlackAuthorizations.create_slack_authorization()

    slack_authorization
  end

  defp counter do
    System.unique_integer([:positive])
  end
end
