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
end
