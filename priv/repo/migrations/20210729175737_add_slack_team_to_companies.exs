defmodule ChatApi.Repo.Migrations.AddSlackTeamToCompanies do
  use Ecto.Migration
  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.{Companies, Repo, SlackAuthorizations, SlackConversationThreads}
  alias ChatApi.Companies.Company
  alias ChatApi.SlackAuthorizations.SlackAuthorization
  alias ChatApi.SlackConversationThreads.SlackConversationThread

  def change do
    alter table(:companies) do
      add(:slack_team_id, :string)
      add(:slack_team_name, :string)
    end

    alter table(:slack_conversation_threads) do
      # TODO: try to backfill these fields based on existing data
      # (Try using conversation type/source + checking channel... channel is probably enough,
      # and most accounts probably only have one Slack authorization anyway?)
      add(:slack_team, :string)
    end

    execute(
      &backfill/0,
      fn -> nil end
    )
  end

  def backfill() do
    Application.ensure_all_started(:hackney)

    auths_by_key = authorizations_by_key()
    backfill_company_slack_team_fields(auths_by_key)
    backfill_conversation_thread_slack_team_field(auths_by_key)
  end

  def keyify(account_id, slack_channel_id), do: "#{account_id}:#{slack_channel_id}"

  def parse_key(key), do: String.split(key, ":")

  def authorizations_by_key() do
    %{}
    |> company_authorizations_by_key()
    |> thread_authorizations_by_key()
    |> fill_missing_authorizations()
  end

  def fill_missing_authorizations(existing \\ %{}) do
    existing
    |> Map.new(fn
      {k, nil} ->
        Logger.warn("Missing authorization for #{k}")
        [account_id, slack_channel_id] = String.split(k, ":")

        auth =
          account_id
          |> SlackAuthorizations.list_slack_authorizations_by_account()
          |> SlackAuthorizations.find_authorization_with_channel(slack_channel_id)

        {k, auth}

      {k, %SlackAuthorization{} = auth} ->
        {k, auth}
    end)
  end

  def company_authorizations_by_key(existing \\ %{}) do
    Company
    |> select([
      :account_id,
      :slack_channel_id
    ])
    |> Repo.all()
    |> Enum.map(&keyify(&1.account_id, &1.slack_channel_id))
    |> Enum.uniq()
    |> Map.new(fn key ->
      [account_id, slack_channel_id] = parse_key(key)

      authorizations =
        SlackAuthorizations.list_slack_authorizations_by_account(account_id, %{
          type: "support"
        })

      case authorizations do
        [auth] ->
          {key, auth}

        [_ | _] = authorizations ->
          Logger.warn(
            "Unexpected state -- there should not be multiple authorizations for #{inspect(key)}"
          )

          auth =
            Map.get(
              existing,
              key,
              SlackAuthorizations.find_authorization_with_channel(
                authorizations,
                slack_channel_id
              )
            )

          {key, auth}
      end
    end)
    # TODO: maybe a reduce makes more sense?
    |> Map.merge(existing)
  end

  def thread_authorizations_by_key(existing \\ %{}) do
    SlackConversationThread
    |> select([
      :account_id,
      :slack_channel
    ])
    |> Repo.all()
    |> Enum.map(&keyify(&1.account_id, &1.slack_channel))
    |> Map.new(fn key ->
      [account_id, slack_channel_id] = parse_key(key)
      authorizations = SlackAuthorizations.list_slack_authorizations_by_account(account_id)

      auth =
        case Map.get(existing, key) do
          nil ->
            Enum.find(authorizations, fn a -> a.channel_id == slack_channel_id end)

          %SlackAuthorization{} = auth ->
            auth
        end

      {key, auth}
    end)
    # TODO: maybe a reduce makes more sense?
    |> Map.merge(existing)
  end

  def backfill_company_slack_team_fields(auths_by_key) do
    Company
    |> select([
      :id,
      :name,
      :account_id,
      :slack_channel_id,
      :slack_channel_name,
      :slack_team_id,
      :slack_team_name
    ])
    |> Repo.all()
    |> Enum.map(fn
      %Company{
        account_id: account_id,
        slack_channel_id: slack_channel_id,
        slack_team_name: nil,
        slack_team_id: nil
      } = company
      when is_binary(slack_channel_id) ->
        key = keyify(account_id, slack_channel_id)
        auth = Map.get(auths_by_key, key)

        case auth do
          %SlackAuthorization{team_name: slack_team_name, team_id: slack_team_id} ->
            {:ok, result} =
              Companies.update_company(company, %{
                slack_team_name: slack_team_name,
                slack_team_id: slack_team_id
              })

            Logger.info("Company successfully updated: #{inspect(result)}")

          _ ->
            nil
        end

      _ ->
        nil
    end)
  end

  def backfill_conversation_thread_slack_team_field(auths_by_key) do
    SlackConversationThread
    |> select([
      :id,
      :slack_channel,
      :slack_thread_ts,
      :conversation_id,
      :account_id
    ])
    |> Repo.all()
    |> Enum.map(fn
      %SlackConversationThread{
        account_id: account_id,
        slack_channel: slack_channel_id,
        slack_team: nil
      } = thread
      when is_binary(slack_channel_id) ->
        key = keyify(account_id, slack_channel_id)
        auth = Map.get(auths_by_key, key)

        case auth do
          %SlackAuthorization{team_id: slack_team_id} ->
            {:ok, result} =
              SlackConversationThreads.update_slack_conversation_thread(thread, %{
                slack_team: slack_team_id
              })

            Logger.info("Thread successfully updated: #{inspect(result)}")

          _ ->
            nil
        end

      _ ->
        nil
    end)
  end
end
