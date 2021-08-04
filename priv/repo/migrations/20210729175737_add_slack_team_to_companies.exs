defmodule ChatApi.Repo.Migrations.AddSlackTeamToCompanies do
  use Ecto.Migration
  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.{Repo, SlackAuthorizations}
  alias ChatApi.Companies.Company
  alias ChatApi.SlackAuthorizations.SlackAuthorization
  alias ChatApi.SlackConversationThreads.SlackConversationThread

  def change do
    alter table(:companies) do
      add(:slack_team_id, :string)
      add(:slack_team_name, :string)
    end

    alter table(:slack_conversation_threads) do
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
    companies = backfill_company_slack_team_fields(auths_by_key)
    threads = backfill_conversation_thread_slack_team_field(auths_by_key)

    Logger.info("Companies updated: #{inspect(companies)}")
    Logger.info("Threads updated: #{inspect(threads)}")
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
    companies =
      Company
      |> select([
        :account_id,
        :slack_channel_id
      ])
      |> Repo.all()

    auths_by_account =
      companies
      |> Enum.map(& &1.account_id)
      |> Enum.uniq()
      |> Map.new(fn account_id ->
        authorizations =
          SlackAuthorizations.list_slack_authorizations_by_account(account_id, %{
            type: "support"
          })

        {account_id, authorizations}
      end)

    keys =
      companies
      |> Enum.map(&keyify(&1.account_id, &1.slack_channel_id))
      |> Enum.uniq()

    Map.new(keys, fn key ->
      [account_id, slack_channel_id] = parse_key(key)
      authorizations = Map.get(auths_by_account, account_id)

      case authorizations do
        [] ->
          {key, nil}

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
    threads =
      SlackConversationThread
      |> select([
        :account_id,
        :slack_channel
      ])
      |> Repo.all()

    auths_by_account =
      threads
      |> Enum.map(& &1.account_id)
      |> Enum.uniq()
      |> Map.new(fn account_id ->
        authorizations = SlackAuthorizations.list_slack_authorizations_by_account(account_id)

        {account_id, authorizations}
      end)

    keys =
      threads
      |> Enum.map(&keyify(&1.account_id, &1.slack_channel))
      |> Enum.uniq()

    Map.new(keys, fn key ->
      [account_id, slack_channel_id] = parse_key(key)
      authorizations = Map.get(auths_by_account, account_id)

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
    auths_by_key
    |> Enum.filter(fn
      {_k, %SlackAuthorization{}} -> true
      {_k, _auth} -> false
    end)
    |> Enum.map(fn {key, auth} ->
      [account_id, slack_channel_id] = parse_key(key)

      {n, _} =
        Company
        |> where(account_id: ^account_id)
        |> where(slack_channel_id: ^slack_channel_id)
        |> where([c], is_nil(c.slack_team_id))
        |> where([c], is_nil(c.slack_team_name))
        |> Repo.update_all(set: [slack_team_id: auth.team_id, slack_team_name: auth.team_name])

      n
    end)
    |> Enum.sum()
  end

  def backfill_conversation_thread_slack_team_field(auths_by_key) do
    auths_by_key
    |> Enum.filter(fn
      {_k, %SlackAuthorization{}} -> true
      {_k, _auth} -> false
    end)
    |> Enum.map(fn {key, auth} ->
      [account_id, slack_channel_id] = parse_key(key)

      {n, _} =
        SlackConversationThread
        |> where(account_id: ^account_id)
        |> where(slack_channel: ^slack_channel_id)
        |> where([t], is_nil(t.slack_team))
        |> Repo.update_all(set: [slack_team: auth.team_id])

      n
    end)
    |> Enum.sum()
  end
end
