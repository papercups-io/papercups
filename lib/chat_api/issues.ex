defmodule ChatApi.Issues do
  @moduledoc """
  The Issues context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.Issues.Issue
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer

  @spec list_issues(binary()) :: [Issue.t()]
  def list_issues(account_id) do
    Issue |> where(account_id: ^account_id) |> Repo.all()
  end

  @spec get_issue!(binary()) :: Issue.t()
  def get_issue!(id) do
    Issue |> Repo.get!(id)
  end

  @spec find_issue(map()) :: Issue.t() | nil
  def find_issue(filters \\ %{}) do
    Issue
    |> where(^filter_where(filters))
    |> first()
    |> Repo.one()
  end

  @spec create_issue(map()) :: {:ok, Issue.t()} | {:error, Ecto.Changeset.t()}
  def create_issue(attrs \\ %{}) do
    %Issue{}
    |> Issue.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_issue(Issue.t(), map()) :: {:ok, Issue.t()} | {:error, Ecto.Changeset.t()}
  def update_issue(%Issue{} = issue, attrs) do
    issue
    |> Issue.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_issue(Issue.t()) :: {:ok, Issue.t()} | {:error, Ecto.Changeset.t()}
  def delete_issue(%Issue{} = issue) do
    Repo.delete(issue)
  end

  @spec change_issue(Issue.t(), map()) :: Ecto.Changeset.t()
  def change_issue(%Issue{} = issue, attrs \\ %{}) do
    Issue.changeset(issue, attrs)
  end

  @spec list_customers_by_issue(binary()) :: [Customer.t()]
  def list_customers_by_issue(issue_id) do
    Issue
    |> preload(:customers)
    |> Repo.get!(issue_id)
    |> Map.get(:customers)
  end

  @spec list_conversations_by_issue(binary()) :: [Conversation.t()]
  def list_conversations_by_issue(issue_id) do
    Issue
    |> preload(:conversations)
    |> Repo.get!(issue_id)
    |> Map.get(:conversations)
  end

  @spec filter_where(map()) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([p], ^dynamic and p.account_id == ^value)

      {:state, value}, dynamic ->
        dynamic([p], ^dynamic and p.state == ^value)

      {:title, value}, dynamic ->
        dynamic([p], ^dynamic and p.title == ^value)

      {:github_issue_url, value}, dynamic ->
        dynamic([p], ^dynamic and p.github_issue_url == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
