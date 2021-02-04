defmodule ChatApi.Slack.Validation do
  require Logger

  alias ChatApi.{
    Companies,
    Slack,
    SlackConversationThreads
  }

  alias ChatApi.SlackAuthorizations.SlackAuthorization

  @spec validate_non_admin_user(any(), binary()) :: :ok | :error
  def validate_non_admin_user(authorization, slack_user_id) do
    case Slack.Helpers.find_matching_user(authorization, slack_user_id) do
      nil -> :ok
      _match -> :error
    end
  end

  @spec validate_channel_supported(any(), binary()) :: :ok | :error
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
      nil -> :error
      _company -> :ok
    end
  end

  def validate_channel_supported(_authorization, _slack_channel_id), do: :error

  @spec validate_no_existing_company(binary(), binary()) :: :ok | :error
  def validate_no_existing_company(account_id, slack_channel_id) do
    case Companies.find_by_slack_channel(account_id, slack_channel_id) do
      nil -> :ok
      _company -> :error
    end
  end

  @spec validate_no_existing_thread(binary(), binary()) :: :ok | :error
  def validate_no_existing_thread(channel, ts) do
    case SlackConversationThreads.exists?(%{"slack_thread_ts" => ts, "slack_channel" => channel}) do
      false -> :ok
      true -> :error
    end
  end
end
