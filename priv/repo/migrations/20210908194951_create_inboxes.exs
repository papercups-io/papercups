defmodule ChatApi.Repo.Migrations.CreateInboxes do
  use Ecto.Migration
  import Ecto.Query, warn: false
  require Logger

  alias ChatApi.{Inboxes, Repo}
  alias ChatApi.Accounts.Account
  alias ChatApi.Conversations.Conversation
  alias ChatApi.ForwardingAddresses.ForwardingAddress
  alias ChatApi.Google.GoogleAuthorization
  alias ChatApi.Mattermost.MattermostAuthorization
  alias ChatApi.SlackAuthorizations.SlackAuthorization
  alias ChatApi.Twilio.TwilioAuthorization
  alias ChatApi.Users.User
  alias ChatApi.WidgetSettings.WidgetSetting

  def change do
    create table(:inboxes, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:description, :string)
      add(:slug, :string)
      add(:is_primary, :boolean, default: false, null: false)
      add(:is_private, :boolean, default: false, null: false)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:inboxes, [:account_id]))

    create table(:inbox_members, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:role, :string, null: false)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
      add(:inbox_id, references(:inboxes, type: :uuid, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, type: :integer, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:inbox_members, [:account_id]))
    create(index(:inbox_members, [:inbox_id]))
    create(index(:inbox_members, [:user_id]))

    alter table(:conversations) do
      add(:inbox_id, references(:inboxes, type: :uuid, on_delete: :delete_all))
    end

    create(index(:conversations, [:inbox_id]))

    alter table(:forwarding_addresses) do
      add(:inbox_id, references(:inboxes, type: :uuid, on_delete: :delete_all))
    end

    create(index(:forwarding_addresses, [:inbox_id]))

    alter table(:google_authorizations) do
      add(:inbox_id, references(:inboxes, type: :uuid, on_delete: :delete_all))
    end

    create(index(:google_authorizations, [:inbox_id]))

    alter table(:mattermost_authorizations) do
      add(:inbox_id, references(:inboxes, type: :uuid, on_delete: :delete_all))
    end

    create(index(:mattermost_authorizations, [:inbox_id]))

    alter table(:slack_authorizations) do
      add(:inbox_id, references(:inboxes, type: :uuid, on_delete: :delete_all))
    end

    create(index(:slack_authorizations, [:inbox_id]))

    alter table(:twilio_authorizations) do
      add(:inbox_id, references(:inboxes, type: :uuid, on_delete: :delete_all))
    end

    create(index(:twilio_authorizations, [:inbox_id]))

    alter table(:widget_settings) do
      add(:inbox_id, references(:inboxes, type: :uuid, on_delete: :delete_all))
    end

    create(index(:widget_settings, [:inbox_id]))

    execute(
      &seed_inbox_data/0,
      fn -> nil end
    )
  end

  def seed_inbox_data() do
    inboxes_by_account = create_primary_inbox_by_account()

    seed_primary_inboxes(inboxes_by_account)
    seed_inbox_members(inboxes_by_account)
  end

  def seed_primary_inboxes(inboxes_by_account) do
    models = [
      Conversation,
      GoogleAuthorization,
      ForwardingAddress,
      MattermostAuthorization,
      SlackAuthorization,
      TwilioAuthorization,
      WidgetSetting
    ]

    for model <- models do
      results = set_inbox_id_by_model(model, inboxes_by_account)

      Logger.info("Updated #{results} records for model: #{inspect(model)}")
    end

    inboxes_by_account
  end

  def seed_inbox_members(inboxes_by_account) do
    results =
      Enum.flat_map(inboxes_by_account, fn {account_id, inbox_id} ->
        User
        |> select([:id, :role])
        |> where(account_id: ^account_id)
        |> where([u], is_nil(u.disabled_at))
        |> where([u], is_nil(u.archived_at))
        |> Repo.all()
        |> Enum.map(fn user ->
          {:ok, result} =
            Inboxes.create_inbox_member(%{
              inbox_id: inbox_id,
              account_id: account_id,
              user_id: user.id,
              role: user.role
            })

          result
        end)
      end)

    Logger.info("Added #{length(results)} users to the primary inboxes")
  end

  def create_primary_inbox_by_account() do
    Account
    |> Repo.all()
    |> Enum.map(fn account ->
      {:ok, inbox} =
        Inboxes.create_inbox(%{
          account_id: account.id,
          name: "Primary Inbox",
          description:
            "This is the primary Papercups inbox for #{account.company_name}. All messages will flow into here by default.",
          is_primary: true,
          is_private: false
        })

      {account.id, inbox.id}
    end)
    |> Map.new()
  end

  def set_inbox_id_by_model(model, inboxes_by_account) do
    inboxes_by_account
    |> Enum.map(fn {account_id, inbox_id} ->
      {n, _} =
        model
        |> where(account_id: ^account_id)
        |> Repo.update_all(set: [inbox_id: inbox_id])

      n
    end)
    |> Enum.sum()
  end
end
