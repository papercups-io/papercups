defmodule ChatApi.SlackAuthorizations do
  @moduledoc """
  The SlackAuthorizations context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.SlackAuthorizations.SlackAuthorization

  @spec list_slack_authorizations() :: [SlackAuthorization.t()]
  def list_slack_authorizations do
    Repo.all(SlackAuthorization)
  end

  @spec get_slack_authorization!(binary()) :: SlackAuthorization.t()
  def get_slack_authorization!(id), do: Repo.get!(SlackAuthorization, id)

  @spec find_slack_authorization(map()) :: SlackAuthorization.t() | nil
  def find_slack_authorization(filters \\ %{}) do
    SlackAuthorization
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec get_authorization_by_account(binary()) :: SlackAuthorization.t() | nil
  def get_authorization_by_account(account_id) do
    SlackAuthorization
    |> where(account_id: ^account_id)
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec create_or_update(binary(), map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update(account_id, params) do
    existing = get_authorization_by_account(account_id)

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

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:channel_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.channel_id == ^value)

      {:team_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.team_id == ^value)

      {:type, value}, dynamic ->
        dynamic([r], ^dynamic and r.type == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
