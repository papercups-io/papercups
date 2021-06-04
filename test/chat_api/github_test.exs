defmodule ChatApi.GithubTest do
  use ChatApi.DataCase
  import ChatApi.Factory
  alias ChatApi.Github

  describe "github_authorizations" do
    alias ChatApi.Github.GithubAuthorization

    @valid_attrs %{
      access_token: "some access_token",
      metadata: %{},
      scope: "some scope",
      token_type: "some token_type"
    }
    @update_attrs %{
      access_token: "some updated access_token",
      metadata: %{},
      scope: "some updated scope",
      token_type: "some updated token_type"
    }
    @invalid_attrs %{
      access_token: nil,
      account_id: nil,
      metadata: nil,
      scope: nil,
      token_type: nil,
      user_id: nil
    }

    setup do
      account = insert(:account)
      user = insert(:user, account: account, role: "admin")
      github_authorization = insert(:github_authorization, account: account, user: user)

      {:ok, account: account, user: user, github_authorization: github_authorization}
    end

    test "list_github_authorizations/0 returns all github_authorizations", %{
      github_authorization: github_authorization
    } do
      assert Github.list_github_authorizations() |> Enum.map(&extract_comparable_fields/1) == [
               extract_comparable_fields(github_authorization)
             ]
    end

    test "get_github_authorization!/1 returns the github_authorization with given id", %{
      github_authorization: github_authorization
    } do
      result = Github.get_github_authorization!(github_authorization.id)

      assert extract_comparable_fields(result) == extract_comparable_fields(github_authorization)
    end

    test "create_github_authorization/1 with valid data creates a github_authorization", %{
      account: account,
      user: user
    } do
      params = Map.merge(@valid_attrs, %{user_id: user.id, account_id: account.id})

      assert {:ok, %GithubAuthorization{} = github_authorization} =
               Github.create_github_authorization(params)

      assert github_authorization.access_token == "some access_token"
      assert github_authorization.account_id == account.id
      assert github_authorization.metadata == %{}
      assert github_authorization.scope == "some scope"
      assert github_authorization.token_type == "some token_type"
      assert github_authorization.user_id == user.id
    end

    test "create_github_authorization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Github.create_github_authorization(@invalid_attrs)
    end

    test "update_github_authorization/2 with valid data updates the github_authorization", %{
      github_authorization: github_authorization
    } do
      assert {:ok, %GithubAuthorization{} = github_authorization} =
               Github.update_github_authorization(github_authorization, @update_attrs)

      assert github_authorization.access_token == "some updated access_token"
      assert github_authorization.metadata == %{}
      assert github_authorization.scope == "some updated scope"
      assert github_authorization.token_type == "some updated token_type"
    end

    test "update_github_authorization/2 with invalid data returns error changeset", %{
      github_authorization: github_authorization
    } do
      assert {:error, %Ecto.Changeset{}} =
               Github.update_github_authorization(github_authorization, @invalid_attrs)

      current = Github.get_github_authorization!(github_authorization.id)

      assert extract_comparable_fields(current) == extract_comparable_fields(github_authorization)
    end

    test "delete_github_authorization/1 deletes the github_authorization", %{
      github_authorization: github_authorization
    } do
      assert {:ok, %GithubAuthorization{}} =
               Github.delete_github_authorization(github_authorization)

      assert_raise Ecto.NoResultsError, fn ->
        Github.get_github_authorization!(github_authorization.id)
      end
    end

    test "change_github_authorization/1 returns a github_authorization changeset", %{
      github_authorization: github_authorization
    } do
      assert %Ecto.Changeset{} = Github.change_github_authorization(github_authorization)
    end

    defp extract_comparable_fields(github_authorization) do
      Map.take(github_authorization, [:access_token, :scope, :token_type, :account_id, :user_id])
    end
  end

  describe "helpers" do
    test "Github.Helpers.extract_github_issue_links/1 handles strings without GitHub issue links" do
      assert [] = Github.Helpers.extract_github_issue_links("")
      assert [] = Github.Helpers.extract_github_issue_links("hello world")

      assert [] =
               Github.Helpers.extract_github_issue_links(
                 "check out my website: www.papercups.io, https://papercups.io"
               )

      assert [] =
               Github.Helpers.extract_github_issue_links(
                 "here's our github repo: https://github.com/papercups-io/papercups"
               )

      assert [] =
               Github.Helpers.extract_github_issue_links(
                 "here's our github repo: https://github.com/papercups-io/papercups/commit/a097f9xxx08885"
               )
    end

    test "Github.Helpers.extract_github_issue_links/1 handles strings with one GitHub issue link" do
      assert ["http://github.com/papercups-io/papercups/issues/1"] =
               Github.Helpers.extract_github_issue_links(
                 "http://github.com/papercups-io/papercups/issues/1"
               )

      assert ["https://github.com/papercups-io/papercups/issues/1"] =
               Github.Helpers.extract_github_issue_links(
                 "https://github.com/papercups-io/papercups/issues/1"
               )

      assert ["https://github.com/papercups-io/papercups/issues/1"] =
               Github.Helpers.extract_github_issue_links(
                 "check out this issue: https://github.com/papercups-io/papercups/issues/1"
               )

      assert ["https://github.com/papercups-io/papercups/issues/1"] =
               Github.Helpers.extract_github_issue_links(
                 "https://github.com/papercups-io/papercups/issues/1 is the url"
               )

      assert ["https://github.com/papercups-io/papercups/issues/1"] =
               Github.Helpers.extract_github_issue_links(
                 "here you go: https://github.com/papercups-io/papercups/issues/1 hope it helps!"
               )
    end

    test "Github.Helpers.extract_github_issue_links/1 handles strings with multiple GitHub issue links" do
      str = """
      here are the github issues we're working on this week:

      - https://github.com/papercups-io/papercups/issues/1
      - http://github.com/papercups-io/chat/issues/2
      - https://github.com/papercups-io/widget/issues/3
      - https://github.com/alex/website/issues/4

      let us know if you want to help out!
      """

      assert [
               "https://github.com/papercups-io/papercups/issues/1",
               "http://github.com/papercups-io/chat/issues/2",
               "https://github.com/papercups-io/widget/issues/3",
               "https://github.com/alex/website/issues/4"
             ] = Github.Helpers.extract_github_issue_links(str)
    end

    test "Github.Helpers.contains_github_issue_link?/1 handles strings without GitHub issue links" do
      refute Github.Helpers.contains_github_issue_link?("")
      refute Github.Helpers.contains_github_issue_link?("hello world")

      refute Github.Helpers.contains_github_issue_link?(
               "check out my website: www.papercups.io, https://papercups.io"
             )

      refute Github.Helpers.contains_github_issue_link?(
               "here's our github repo: https://github.com/papercups-io/papercups"
             )

      refute Github.Helpers.contains_github_issue_link?(
               "here's our github repo: https://github.com/papercups-io/papercups/commit/a097f9xxx08885"
             )
    end

    test "Github.Helpers.contains_github_issue_link?/1 handles strings with one GitHub issue link" do
      assert Github.Helpers.contains_github_issue_link?(
               "http://github.com/papercups-io/papercups/issues/1"
             )

      assert Github.Helpers.contains_github_issue_link?(
               "https://github.com/papercups-io/papercups/issues/1"
             )

      assert Github.Helpers.contains_github_issue_link?(
               "check out this issue: https://github.com/papercups-io/papercups/issues/1"
             )

      assert Github.Helpers.contains_github_issue_link?(
               "https://github.com/papercups-io/papercups/issues/1 is the url"
             )

      assert Github.Helpers.contains_github_issue_link?(
               "here you go: https://github.com/papercups-io/papercups/issues/1 hope it helps!"
             )
    end

    test "Github.Helpers.contains_github_issue_link?/1 handles strings with multiple GitHub issue links" do
      str = """
      here are the github issues we're working on this week:

      - https://github.com/papercups-io/papercups/issues/1
      - http://github.com/papercups-io/chat/issues/2
      - https://github.com/papercups-io/widget/issues/3
      - https://github.com/alex/website/issues/4

      let us know if you want to help out!
      """

      assert Github.Helpers.contains_github_issue_link?(str)
    end

    test "Github.Helpers.parse_github_issue_url/1 extracts the owner, repo, and id of the issue" do
      assert {:ok, %{owner: "papercups-io", repo: "papercups", id: "1"}} =
               Github.Helpers.parse_github_issue_url(
                 "https://github.com/papercups-io/papercups/issues/1"
               )

      assert {:ok, %{owner: "papercups-io", repo: "chat", id: "2"}} =
               Github.Helpers.parse_github_issue_url(
                 "http://github.com/papercups-io/chat/issues/2"
               )

      assert {:ok, %{owner: "papercups-io", repo: "widget", id: "3"}} =
               Github.Helpers.parse_github_issue_url(
                 "https://github.com/papercups-io/widget/issues/3"
               )

      assert {:ok, %{owner: "alex", repo: "website", id: "4"}} =
               Github.Helpers.parse_github_issue_url("https://github.com/alex/website/issues/4")

      assert {:error, :invalid_github_issue_url} =
               Github.Helpers.parse_github_issue_url(
                 "https://github.com/papercups-io/papercups/commit/a097f9xxx08885"
               )
    end
  end
end
