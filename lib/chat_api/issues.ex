defmodule ChatApi.Issues do
  @moduledoc """
  The Issues context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Github, Repo}
  alias ChatApi.Issues.Issue
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer

  @spec list_issues(binary(), map()) :: [Issue.t()]
  def list_issues(account_id, filters \\ %{}) do
    Issue
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> filter_by_customer(filters)
    |> Repo.all()
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

  @spec find_by_github_url(binary(), binary()) :: Issue.t() | nil
  def find_by_github_url(account_id, url),
    do: find_issue(%{account_id: account_id, github_issue_url: url})

  @spec create_issue(map()) :: {:ok, Issue.t()} | {:error, Ecto.Changeset.t()}
  def create_issue(attrs \\ %{}) do
    %Issue{}
    |> Issue.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_from_github_url(binary(), map()) :: {:error, any} | {:ok, Issue.t()}
  def create_from_github_url(url, %{account_id: account_id, creator_id: _creator_id} = attrs) do
    authorization = Github.get_authorization_by_account(account_id)

    with {:ok, %{owner: owner, repo: repo, id: id}} <- Github.Helpers.parse_github_issue_url(url),
         {:ok, %{body: %{"title" => title, "body" => body, "state" => state}}} <-
           Github.Client.retrieve_issue(authorization, owner, repo, id) do
      attrs
      |> Map.merge(%{
        title: title,
        body: body,
        github_issue_url: url,
        state: Github.Helpers.parse_github_issue_state(state)
      })
      |> create_issue()
    end
  end

  @spec find_or_create_by_github_url(binary(), map()) :: {:error, any} | {:ok, Issue.t()}
  def find_or_create_by_github_url(
        url,
        %{account_id: account_id, creator_id: _creator_id} = attrs
      ) do
    case find_by_github_url(account_id, url) do
      nil -> create_from_github_url(url, attrs)
      %Issue{} = issue -> {:ok, issue}
    end
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
    |> Map.get(:customers, [])
  end

  @spec list_conversations_by_issue(binary()) :: [Conversation.t()]
  def list_conversations_by_issue(issue_id) do
    Issue
    |> preload(:conversations)
    |> Repo.get!(issue_id)
    |> Map.get(:conversations)
  end

  @spec filter_by_customer(Ecto.Query.t(), map()) :: Ecto.Query.t()
  def filter_by_customer(query, %{"customer_id" => customer_id}) when not is_nil(customer_id) do
    query
    |> join(:left, [i], c in assoc(i, :customers))
    |> where([_i, c], c.id == ^customer_id)
  end

  def filter_by_customer(query, _filters), do: query

  @spec filter_where(map()) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    params
    |> Map.new(fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
    |> Enum.reduce(dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:state, value}, dynamic ->
        dynamic([r], ^dynamic and r.state == ^value)

      {:title, value}, dynamic ->
        dynamic([r], ^dynamic and r.title == ^value)

      {:github_issue_url, value}, dynamic ->
        dynamic([r], ^dynamic and r.github_issue_url == ^value)

      {:q, ""}, dynamic ->
        dynamic

      {:q, query}, dynamic ->
        value = "%" <> query <> "%"

        dynamic(
          [r],
          ^dynamic and
            (ilike(r.title, ^value) or ilike(r.body, ^value) or ilike(r.github_issue_url, ^value))
        )

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
