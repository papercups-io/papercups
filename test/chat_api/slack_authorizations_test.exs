defmodule ChatApi.SlackAuthorizationsTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.SlackAuthorizations

  describe "slack_authorizations" do
    alias ChatApi.SlackAuthorizations.SlackAuthorization

    @update_attrs %{
      access_token: "some updated access_token",
      app_id: "some updated app_id",
      authed_user_id: "some updated authed_user_id",
      bot_user_id: "some updated bot_user_id",
      channel: "some updated channel",
      channel_id: "some updated channel_id",
      configuration_url: "some updated configuration_url",
      scope: "some updated scope",
      team_id: "some updated team_id",
      team_name: "some updated team_name",
      token_type: "some updated token_type",
      webhook_url: "some updated webhook_url",
      type: "reply"
    }
    @invalid_attrs %{
      access_token: nil,
      app_id: nil,
      authed_user_id: nil,
      bot_user_id: nil,
      channel: nil,
      channel_id: nil,
      configuration_url: nil,
      scope: nil,
      team_id: nil,
      team_name: nil,
      token_type: nil,
      webhook_url: nil
    }

    setup do
      {:ok, slack_authorization: insert(:slack_authorization)}
    end

    test "list_slack_authorizations/0 returns all slack_authorizations",
         %{slack_authorization: slack_authorization} do
      slack_authorization_ids =
        SlackAuthorizations.list_slack_authorizations()
        |> Enum.map(& &1.id)

      assert slack_authorization_ids == [slack_authorization.id]
    end

    test "list_slack_authorizations/1 returns all slack_authorizations that match the filters" do
      auth_1 = insert(:slack_authorization, type: "support")
      _auth_2 = insert(:slack_authorization, type: "reply")
      auth_3 = insert(:slack_authorization, type: "support")

      slack_authorization_ids =
        SlackAuthorizations.list_slack_authorizations(%{type: "support"})
        |> Enum.map(& &1.id)

      assert Enum.sort(slack_authorization_ids) == Enum.sort([auth_1.id, auth_3.id])
    end

    test "list_slack_authorizations_by_account/1 returns all slack_authorizations for the account",
         %{slack_authorization: slack_authorization} do
      account_id = slack_authorization.account_id

      slack_authorization_ids =
        SlackAuthorizations.list_slack_authorizations_by_account(account_id)
        |> Enum.map(& &1.id)

      assert slack_authorization_ids == [slack_authorization.id]
    end

    test "get_slack_authorization!/1 returns the slack_authorization with given id",
         %{slack_authorization: slack_authorization} do
      assert slack_authorization ==
               SlackAuthorizations.get_slack_authorization!(slack_authorization.id)
               |> Repo.preload([:account])
    end

    test "create_slack_authorization/1 with valid data creates a slack_authorization" do
      attrs = params_with_assocs(:slack_authorization)

      assert {:ok, %SlackAuthorization{}} = SlackAuthorizations.create_slack_authorization(attrs)
    end

    test "create_slack_authorization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SlackAuthorizations.create_slack_authorization(@invalid_attrs)
    end

    test "update_slack_authorization/2 with valid data updates the slack_authorization",
         %{slack_authorization: slack_authorization} do
      assert {:ok, %SlackAuthorization{} = slack_authorization} =
               SlackAuthorizations.update_slack_authorization(slack_authorization, @update_attrs)

      assert slack_authorization.access_token == "some updated access_token"
      assert slack_authorization.app_id == "some updated app_id"
      assert slack_authorization.authed_user_id == "some updated authed_user_id"
      assert slack_authorization.bot_user_id == "some updated bot_user_id"
      assert slack_authorization.channel == "some updated channel"
      assert slack_authorization.channel_id == "some updated channel_id"
      assert slack_authorization.configuration_url == "some updated configuration_url"
      assert slack_authorization.scope == "some updated scope"
      assert slack_authorization.team_id == "some updated team_id"
      assert slack_authorization.team_name == "some updated team_name"
      assert slack_authorization.token_type == "some updated token_type"
      assert slack_authorization.webhook_url == "some updated webhook_url"
    end

    test "update_slack_authorization/2 with invalid data returns error changeset",
         %{slack_authorization: slack_authorization} do
      assert {:error, %Ecto.Changeset{}} =
               SlackAuthorizations.update_slack_authorization(slack_authorization, @invalid_attrs)

      assert slack_authorization ==
               SlackAuthorizations.get_slack_authorization!(slack_authorization.id)
               |> Repo.preload([:account])
    end

    test "update_slack_authorization/2 with an invalid type returns error changeset",
         %{slack_authorization: slack_authorization} do
      assert {:error, %Ecto.Changeset{}} =
               SlackAuthorizations.update_slack_authorization(slack_authorization, %{
                 type: "unknown"
               })
    end

    test "delete_slack_authorization/1 deletes the slack_authorization",
         %{slack_authorization: slack_authorization} do
      assert {:ok, %SlackAuthorization{}} =
               SlackAuthorizations.delete_slack_authorization(slack_authorization)

      assert_raise Ecto.NoResultsError, fn ->
        SlackAuthorizations.get_slack_authorization!(slack_authorization.id)
      end
    end

    test "change_slack_authorization/1 returns a slack_authorization changeset",
         %{slack_authorization: slack_authorization} do
      assert %Ecto.Changeset{} =
               SlackAuthorizations.change_slack_authorization(slack_authorization)
    end

    test "find_slack_authorization/1 finds a slack_authorization matching the provided filters" do
      %{id: slack_authorization_id} =
        insert(:slack_authorization, team_id: "T123", channel_id: "C123", type: "reply")

      assert %{id: ^slack_authorization_id} =
               SlackAuthorizations.find_slack_authorization(%{team_id: "T123"})

      assert %{id: ^slack_authorization_id} =
               SlackAuthorizations.find_slack_authorization(%{team_id: "T123", channel_id: "C123"})

      assert %{id: ^slack_authorization_id} =
               SlackAuthorizations.find_slack_authorization(%{
                 team_id: "T123",
                 channel_id: "C123",
                 type: "reply"
               })

      # With different :type
      refute SlackAuthorizations.find_slack_authorization(%{
               team_id: "T123",
               channel_id: "C123",
               type: "support"
             })

      # With different :team_id
      refute SlackAuthorizations.find_slack_authorization(%{
               team_id: "T321",
               channel_id: "C123",
               type: "reply"
             })

      # With different :channel_id
      refute SlackAuthorizations.find_slack_authorization(%{
               team_id: "T123",
               channel_id: "C321",
               type: "support"
             })
    end

    test "create_or_update/3 creates a new authorization if none is found for the account",
         %{slack_authorization: slack_authorization} do
      new_account = insert(:account)
      params = Map.merge(@update_attrs, %{account_id: new_account.id})

      {:ok, created} = SlackAuthorizations.create_or_update(new_account.id, %{}, params)

      assert created.id != slack_authorization.id
      assert created.access_token == "some updated access_token"
    end

    test "create_or_update/3 creates a new authorization if none is found matching the authorization type",
         %{slack_authorization: slack_authorization} do
      params =
        Map.merge(@update_attrs, %{type: "support", account_id: slack_authorization.account_id})

      {:ok, created} =
        SlackAuthorizations.create_or_update(
          slack_authorization.account_id,
          %{type: "support"},
          params
        )

      assert created.id != slack_authorization.id
      assert created.access_token == "some updated access_token"
    end

    test "create_or_update/3 updates the existing authorization if one is found for the account",
         %{slack_authorization: slack_authorization} do
      {:ok, updated} =
        SlackAuthorizations.create_or_update(slack_authorization.account_id, %{}, @update_attrs)

      assert updated.id == slack_authorization.id
      assert updated.access_token == "some updated access_token"
    end
  end
end
