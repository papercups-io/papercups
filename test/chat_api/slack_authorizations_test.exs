defmodule ChatApi.SlackAuthorizationsTest do
  use ChatApi.DataCase

  alias ChatApi.SlackAuthorizations

  describe "slack_authorizations" do
    alias ChatApi.SlackAuthorizations.SlackAuthorization

    @valid_attrs %{access_token: "some access_token", app_id: "some app_id", authed_user_id: "some authed_user_id", bot_user_id: "some bot_user_id", channel: "some channel", channel_id: "some channel_id", configuration_url: "some configuration_url", scope: "some scope", team_id: "some team_id", team_name: "some team_name", token_type: "some token_type", webhook_url: "some webhook_url"}
    @update_attrs %{access_token: "some updated access_token", app_id: "some updated app_id", authed_user_id: "some updated authed_user_id", bot_user_id: "some updated bot_user_id", channel: "some updated channel", channel_id: "some updated channel_id", configuration_url: "some updated configuration_url", scope: "some updated scope", team_id: "some updated team_id", team_name: "some updated team_name", token_type: "some updated token_type", webhook_url: "some updated webhook_url"}
    @invalid_attrs %{access_token: nil, app_id: nil, authed_user_id: nil, bot_user_id: nil, channel: nil, channel_id: nil, configuration_url: nil, scope: nil, team_id: nil, team_name: nil, token_type: nil, webhook_url: nil}

    def slack_authorization_fixture(attrs \\ %{}) do
      {:ok, slack_authorization} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SlackAuthorizations.create_slack_authorization()

      slack_authorization
    end

    test "list_slack_authorizations/0 returns all slack_authorizations" do
      slack_authorization = slack_authorization_fixture()
      assert SlackAuthorizations.list_slack_authorizations() == [slack_authorization]
    end

    test "get_slack_authorization!/1 returns the slack_authorization with given id" do
      slack_authorization = slack_authorization_fixture()
      assert SlackAuthorizations.get_slack_authorization!(slack_authorization.id) == slack_authorization
    end

    test "create_slack_authorization/1 with valid data creates a slack_authorization" do
      assert {:ok, %SlackAuthorization{} = slack_authorization} = SlackAuthorizations.create_slack_authorization(@valid_attrs)
      assert slack_authorization.access_token == "some access_token"
      assert slack_authorization.app_id == "some app_id"
      assert slack_authorization.authed_user_id == "some authed_user_id"
      assert slack_authorization.bot_user_id == "some bot_user_id"
      assert slack_authorization.channel == "some channel"
      assert slack_authorization.channel_id == "some channel_id"
      assert slack_authorization.configuration_url == "some configuration_url"
      assert slack_authorization.scope == "some scope"
      assert slack_authorization.team_id == "some team_id"
      assert slack_authorization.team_name == "some team_name"
      assert slack_authorization.token_type == "some token_type"
      assert slack_authorization.webhook_url == "some webhook_url"
    end

    test "create_slack_authorization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SlackAuthorizations.create_slack_authorization(@invalid_attrs)
    end

    test "update_slack_authorization/2 with valid data updates the slack_authorization" do
      slack_authorization = slack_authorization_fixture()
      assert {:ok, %SlackAuthorization{} = slack_authorization} = SlackAuthorizations.update_slack_authorization(slack_authorization, @update_attrs)
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

    test "update_slack_authorization/2 with invalid data returns error changeset" do
      slack_authorization = slack_authorization_fixture()
      assert {:error, %Ecto.Changeset{}} = SlackAuthorizations.update_slack_authorization(slack_authorization, @invalid_attrs)
      assert slack_authorization == SlackAuthorizations.get_slack_authorization!(slack_authorization.id)
    end

    test "delete_slack_authorization/1 deletes the slack_authorization" do
      slack_authorization = slack_authorization_fixture()
      assert {:ok, %SlackAuthorization{}} = SlackAuthorizations.delete_slack_authorization(slack_authorization)
      assert_raise Ecto.NoResultsError, fn -> SlackAuthorizations.get_slack_authorization!(slack_authorization.id) end
    end

    test "change_slack_authorization/1 returns a slack_authorization changeset" do
      slack_authorization = slack_authorization_fixture()
      assert %Ecto.Changeset{} = SlackAuthorizations.change_slack_authorization(slack_authorization)
    end
  end
end
