defmodule ChatApi.SlackAuthorizations do
  @moduledoc """
  The SlackAuthorizations context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.{Companies, Repo, Slack}
  alias ChatApi.Companies.Company
  alias ChatApi.SlackAuthorizations.SlackAuthorization
  alias ChatApi.SlackConversationThreads.SlackConversationThread

  @spec list_slack_authorizations(map()) :: [SlackAuthorization.t()]
  def list_slack_authorizations(filters \\ %{}) do
    SlackAuthorization
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @spec list_slack_authorizations_by_account(binary(), map()) :: [SlackAuthorization.t()]
  def list_slack_authorizations_by_account(account_id, filters \\ %{}) do
    filters |> Map.merge(%{account_id: account_id}) |> list_slack_authorizations()
  end

  @spec get_slack_authorization!(binary()) :: SlackAuthorization.t()
  def get_slack_authorization!(id), do: Repo.get!(SlackAuthorization, id)

  @spec find_slack_authorization(map()) :: SlackAuthorization.t() | nil
  def find_slack_authorization(filters \\ %{}) do
    SlackAuthorization
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @spec get_authorization_by_account(binary(), map()) :: SlackAuthorization.t() | nil
  def get_authorization_by_account(account_id, filters \\ %{}) do
    SlackAuthorization
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @spec create_or_update(binary(), map(), map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update(account_id, filters, params) do
    existing = get_authorization_by_account(account_id, filters)

    if existing do
      update_slack_authorization(existing, params)
    else
      create_slack_authorization(params)
    end
  end

  @spec create_slack_authorization(map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_slack_authorization(attrs \\ %{}) do
    %SlackAuthorization{}
    |> SlackAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_slack_authorization(SlackAuthorization.t(), map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_slack_authorization(%SlackAuthorization{} = slack_authorization, attrs) do
    slack_authorization
    |> SlackAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_slack_authorization(SlackAuthorization.t()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_slack_authorization(%SlackAuthorization{} = slack_authorization) do
    Repo.delete(slack_authorization)
  end

  @spec change_slack_authorization(SlackAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_slack_authorization(%SlackAuthorization{} = slack_authorization, attrs \\ %{}) do
    SlackAuthorization.changeset(slack_authorization, attrs)
  end

  @spec has_authorization_scope?(SlackAuthorization.t(), binary()) :: boolean()
  def has_authorization_scope?(%SlackAuthorization{scope: full_scope}, scope) do
    String.contains?(full_scope, scope)
  end

  @spec get_authorization_settings(SlackAuthorization.t()) :: map()
  def get_authorization_settings(%SlackAuthorization{settings: nil}),
    do: %{
      sync_all_incoming_threads: true,
      sync_by_emoji_tagging: true,
      sync_trigger_emoji: "eyes",
      forward_synced_messages_to_reply_channel: true
    }

  def get_authorization_settings(%SlackAuthorization{settings: settings}), do: settings

  @spec can_access_channel?(SlackAuthorization.t(), binary()) :: boolean()
  def can_access_channel?(%SlackAuthorization{access_token: access_token}, slack_channel_id) do
    case Slack.Client.retrieve_channel_info(slack_channel_id, access_token) do
      {:ok, %{body: %{"ok" => true}}} ->
        true

      {:ok, %{body: %{"ok" => false, "error" => error}}} ->
        Logger.debug("Cannot access channel #{slack_channel_id}: #{inspect(error)}")

        false

      error ->
        Logger.debug("Cannot access channel #{slack_channel_id}: #{inspect(error)}")

        false
    end
  end

  def can_access_channel?(_, _), do: false

  @spec find_authorization_with_channel([SlackAuthorization.t()], binary()) ::
          SlackAuthorization.t() | nil
  def find_authorization_with_channel(authorizations, slack_channel_id),
    do: Enum.find(authorizations, &can_access_channel?(&1, slack_channel_id))

  @spec find_support_authorization_by_company(Company.t() | nil) :: SlackAuthorization.t() | nil
  def find_support_authorization_by_company(company) do
    case company do
      %Company{account_id: account_id, slack_channel_id: slack_channel_id, slack_team_id: nil} ->
        account_id
        |> list_slack_authorizations_by_account(%{type: "support"})
        |> find_authorization_with_channel(slack_channel_id)

      %Company{account_id: account_id, slack_team_id: slack_team_id} ->
        get_authorization_by_account(account_id, %{
          type: "support",
          team_id: slack_team_id
        })

      _ ->
        nil
    end
  end

  @spec find_support_authorization_by_channel(binary) :: SlackAuthorization.t() | nil
  def find_support_authorization_by_channel(slack_channel_id) do
    case Companies.find_by_slack_channel(slack_channel_id) do
      %Company{} = company ->
        find_support_authorization_by_company(company)

      _ ->
        find_slack_authorization(%{
          channel_id: slack_channel_id,
          type: "support"
        })
    end
  end

  @spec find_support_authorization_by_thread(SlackConversationThread.t() | nil) ::
          SlackAuthorization.t() | nil
  def find_support_authorization_by_thread(thread) do
    case thread do
      %SlackConversationThread{
        account_id: account_id,
        slack_channel: slack_channel_id,
        slack_team: nil
      } ->
        get_authorization_by_account(account_id, %{
          type: "support",
          channel_id: slack_channel_id
        })

      %SlackConversationThread{
        account_id: account_id,
        slack_channel: slack_channel_id,
        slack_team: slack_team_id
      } ->
        get_authorization_by_account(account_id, %{
          type: "support",
          team_id: slack_team_id,
          channel_id: slack_channel_id
        })

      _ ->
        nil
    end
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      # TODO: should inbox_id be a required field?
      {:inbox_id, nil}, dynamic ->
        dynamic([r], ^dynamic and is_nil(r.inbox_id))

      {:inbox_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.inbox_id == ^value)

      {:channel_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.channel_id == ^value)

      {:team_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.team_id == ^value)

      {:bot_user_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.bot_user_id == ^value)

      {:type, neq: value}, dynamic ->
        dynamic([r], ^dynamic and r.type != ^value)

      {:type, value}, dynamic ->
        dynamic([r], ^dynamic and r.type == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
