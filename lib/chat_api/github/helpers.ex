defmodule ChatApi.Github.Helpers do
  @moduledoc """
  Helpers for Github context
  """

  alias ChatApi.Github
  alias ChatApi.Github.GithubAuthorization

  @github_issue_regex ~r/https?:\/\/github\.com\/(?:[^\/\s]+\/)+(?:issues\/\d+)/

  @spec extract_github_issue_links(binary()) :: [String.t()]
  def extract_github_issue_links(str) do
    @github_issue_regex
    |> Regex.scan(str)
    |> Enum.map(fn [match] -> match end)
  end

  @spec contains_github_issue_link?(binary()) :: boolean()
  def contains_github_issue_link?(str) do
    case extract_github_issue_links(str) do
      [_ | _] -> true
      [] -> false
    end
  end

  @spec parse_github_issue_url(binary()) ::
          {:error, :invalid_github_issue_url} | {:ok, %{id: binary, owner: binary, repo: binary}}
  def parse_github_issue_url(url) do
    url
    |> extract_github_url_path()
    |> String.split("/")
    |> case do
      [owner, repo, "issues", id] -> {:ok, %{owner: owner, repo: repo, id: id}}
      _ -> {:error, :invalid_github_issue_url}
    end
  end

  @spec parse_github_repo_url(binary()) ::
          {:error, :invalid_github_repo_url} | {:ok, %{owner: binary, repo: binary}}
  def parse_github_repo_url(url) do
    url
    |> extract_github_url_path()
    |> String.split("/")
    |> case do
      [owner, repo | _] -> {:ok, %{owner: owner, repo: repo}}
      _ -> {:error, :invalid_github_repo_url}
    end
  end

  @spec extract_github_url_path(binary()) :: binary()
  def extract_github_url_path(url) do
    case String.split(url, "github.com/") do
      [_protocol, path] -> path
      _ -> ""
    end
  end

  @spec subscribed_to_repo?(binary(), GithubAuthorization.t()) :: boolean()
  def subscribed_to_repo?(github_repo_url, %GithubAuthorization{} = auth) do
    with {:ok, %{body: %{"repositories" => repositories}}} <-
           Github.Client.list_installation_repos(auth, per_page: 100),
         {:ok, %{owner: owner, repo: repo}} <- parse_github_repo_url(github_repo_url) do
      Enum.any?(repositories, fn
        %{"name" => ^repo, "owner" => %{"login" => ^owner}} -> true
        _ -> false
      end)
    else
      _ -> false
    end
  end

  @spec can_access_issue?(binary(), GithubAuthorization.t()) :: boolean()
  def can_access_issue?(url, %GithubAuthorization{} = auth) do
    with {:ok, %{owner: owner, repo: repo, id: id}} <- Github.Helpers.parse_github_issue_url(url),
         {:ok, %{body: %{"title" => _title, "body" => _body, "state" => _state}}} <-
           Github.Client.retrieve_issue(auth, owner, repo, id) do
      true
    else
      _ -> false
    end
  end

  @spec parse_github_issue_state(String.t()) :: String.t()
  def parse_github_issue_state("open"), do: "unstarted"
  def parse_github_issue_state("closed"), do: "done"
  def parse_github_issue_state(_state), do: "unstarted"
end
