defmodule ChatApi.Slack.Validation do
  require Logger

  alias ChatApi.{
    Companies,
    Slack,
    SlackAuthorizations,
    SlackConversationThreads
  }

  alias ChatApi.SlackAuthorizations.SlackAuthorization

  @spec validate_non_admin_user(SlackAuthorization.t(), binary()) :: :ok | :error
  def validate_non_admin_user(authorization, slack_user_id) do
    case Slack.Helpers.find_matching_user(authorization, slack_user_id) do
      nil -> :ok
      _match -> {:error, :existing_user_found}
    end
  end

  @spec validate_channel_supported(SlackAuthorization.t(), binary()) :: :ok | :error
  def validate_channel_supported(
        %SlackAuthorization{channel_id: slack_channel_id},
        slack_channel_id
      ),
      do: :ok

  def validate_channel_supported(
        %SlackAuthorization{account_id: account_id},
        slack_channel_id
      ) do
    case Companies.find_by_slack_channel(account_id, slack_channel_id) do
      nil -> {:error, :channel_not_supported}
      _company -> :ok
    end
  end

  def validate_channel_supported(_authorization, _slack_channel_id), do: :error

  @spec validate_no_existing_company(binary(), binary()) :: :ok | :error
  def validate_no_existing_company(account_id, slack_channel_id) do
    case Companies.find_by_slack_channel(account_id, slack_channel_id) do
      nil -> :ok
      _company -> {:error, :existing_company_found}
    end
  end

  @spec validate_no_existing_thread(binary(), binary()) :: :ok | :error
  def validate_no_existing_thread(channel, ts) do
    case SlackConversationThreads.exists?(%{"slack_thread_ts" => ts, "slack_channel" => channel}) do
      false -> :ok
      true -> {:error, :existing_thread_found}
    end
  end

  @spec validate_authorization_channel_id(binary(), binary(), binary()) :: :ok | :error
  def validate_authorization_channel_id(slack_channel_id, account_id, integration_type) do
    other_slack_authorization_for_account =
      SlackAuthorizations.get_authorization_by_account(account_id, %{
        channel_id: slack_channel_id,
        type: [neq: integration_type]
      })

    potential_duplicate_from_other_account =
      SlackAuthorizations.find_slack_authorization(%{
        channel_id: slack_channel_id,
        type: integration_type
      })

    case {other_slack_authorization_for_account, potential_duplicate_from_other_account} do
      {%SlackAuthorization{} = _existing_with_same_channel, _} ->
        {:error, :duplicate_channel_id}

      # If account_id matches, the user is just reconnecting to the same channel, which is fine
      {_, %SlackAuthorization{account_id: ^account_id}} ->
        :ok

      {_, %SlackAuthorization{account_id: _} = _match_from_different_account} ->
        {:error, :duplicate_channel_id}

      _ ->
        :ok
    end
  end
end
