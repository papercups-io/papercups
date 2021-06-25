defmodule ChatApi.SlackAuthorizations do
  @moduledoc """
  The SlackAuthorizations context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.SlackAuthorizations.SlackAuthorization

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

  @spec create_or_update(binary(), map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update(account_id, params) do
    filters = Map.take(params, [:type])
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

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

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
