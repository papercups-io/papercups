defmodule ChatApi.Companies do
  @moduledoc """
  The Companies context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Companies.Company
  alias ChatApi.SlackConversationThreads.SlackConversationThread

  @spec list_companies(binary(), map()) :: [Company.t()]
  def list_companies(account_id, filters \\ %{}) do
    Company
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec get_company!(binary()) :: Company.t()
  def get_company!(id), do: Repo.get!(Company, id)

  @spec create_company(map()) :: {:ok, Company.t()} | {:error, Ecto.Changeset.t()}
  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_company(Company.t(), map()) :: {:ok, Company.t()} | {:error, Ecto.Changeset.t()}
  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_company(Company.t()) :: {:ok, Company.t()} | {:error, Ecto.Changeset.t()}
  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  @spec change_company(Company.t(), map()) :: Ecto.Changeset.t()
  def change_company(%Company{} = company, attrs \\ %{}) do
    Company.changeset(company, attrs)
  end

  @spec find_by_slack_channel(binary()) :: Company.t() | nil
  def find_by_slack_channel(slack_channel_id) do
    Company
    |> where(slack_channel_id: ^slack_channel_id)
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec find_by_slack_channel(binary(), binary()) :: Company.t() | nil
  def find_by_slack_channel(account_id, slack_channel_id) do
    Company
    |> where(account_id: ^account_id)
    |> where(slack_channel_id: ^slack_channel_id)
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec find_by_account_where(binary(), map()) :: Company.t() | nil
  def find_by_account_where(account_id, filters \\ %{}) do
    Company
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec find_by_slack_conversation_thread(SlackConversationThread.t()) :: Company.t() | nil
  def find_by_slack_conversation_thread(thread) do
    case thread do
      %SlackConversationThread{
        account_id: account_id,
        slack_channel: slack_channel_id,
        slack_team: nil
      } ->
        find_by_account_where(account_id, %{
          slack_channel_id: slack_channel_id
        })

      %SlackConversationThread{
        account_id: account_id,
        slack_channel: slack_channel_id,
        slack_team: slack_team_id
      } ->
        find_by_account_where(account_id, %{
          slack_channel_id: slack_channel_id,
          slack_team_id: slack_team_id
        })

      _ ->
        nil
    end
  end

  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:slack_channel_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.slack_channel_id == ^value)

      {:slack_team_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.slack_team_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
