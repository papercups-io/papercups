defmodule ChatApi.Github.Helpers do
  @moduledoc """
  Helpers for Github context
  """

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
    path =
      case String.split(url, "github.com/") do
        [_protocol, path] -> path
        _ -> ""
      end

    case String.split(path, "/") do
      [owner, repo, "issues", id] -> {:ok, %{owner: owner, repo: repo, id: id}}
      _ -> {:error, :invalid_github_issue_url}
    end
  end

  @spec parse_github_issue_state(String.t()) :: String.t()
  def parse_github_issue_state("open"), do: "unstarted"
  def parse_github_issue_state("closed"), do: "done"
  def parse_github_issue_state(_state), do: "unstarted"
end
