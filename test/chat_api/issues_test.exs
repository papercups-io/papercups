defmodule ChatApi.IssuesTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.Issues

  describe "issues" do
    alias ChatApi.Issues.Issue

    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    setup do
      account = insert(:account)
      issue = insert(:issue, account: account)

      {:ok, account: account, issue: issue}
    end

    test "list_issues/1 returns all issues for the given account", %{
      account: account,
      issue: issue
    } do
      issue_ids = Issues.list_issues(account.id) |> Enum.map(& &1.id)

      assert issue_ids == [issue.id]
    end

    test "get_issue!/1 returns the issue with given id", %{issue: issue} do
      result = Issues.get_issue!(issue.id)

      assert issue.id == result.id
      assert issue.title == result.title
      assert issue.body == result.body
      assert issue.state == result.state
    end

    test "find_issue/1 returns the issue by filters", %{account: account} do
      issue = insert(:issue, account: account, title: "Hello world")
      result = Issues.find_issue(%{title: "Hello world"})

      assert issue.id == result.id

      issue = insert(:issue, account: account, state: "in_progress")
      result = Issues.find_issue(%{state: "in_progress"})

      assert issue.id == result.id

      issue = insert(:issue, account: account, github_issue_url: "https://github.com/issues/1")
      result = Issues.find_issue(%{github_issue_url: "https://github.com/issues/1"})

      assert issue.id == result.id
    end

    test "create_issue/1 with valid data creates a issue" do
      assert {:ok, %Issue{} = issue} =
               Issues.create_issue(params_with_assocs(:issue, title: "new issue"))

      assert issue.title == "new issue"
    end

    test "create_issue/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Issues.create_issue(@invalid_attrs)
    end

    test "update_issue/2 with valid data updates the issue", %{issue: issue} do
      assert {:ok, %Issue{} = issue} = Issues.update_issue(issue, @update_attrs)
      assert issue.title == "some updated title"
    end

    test "update_issue/2 with invalid data returns error changeset",
         %{issue: issue} do
      assert {:error, %Ecto.Changeset{}} = Issues.update_issue(issue, @invalid_attrs)

      current = Issues.get_issue!(issue.id)

      assert issue.id == current.id
      assert issue.title == current.title
      assert issue.body == current.body
      assert issue.state == current.state
    end

    test "delete_issue/1 deletes the issue", %{issue: issue} do
      assert {:ok, %Issue{}} = Issues.delete_issue(issue)
      assert_raise Ecto.NoResultsError, fn -> Issues.get_issue!(issue.id) end
    end

    test "change_issue/1 returns a issue changeset", %{issue: issue} do
      assert %Ecto.Changeset{} = Issues.change_issue(issue)
    end
  end
end
