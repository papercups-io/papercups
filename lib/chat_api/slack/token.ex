defmodule ChatApi.Slack.Token do
  @moduledoc """
  Slack access token helpers
  """

  @spec is_valid_access_token?(binary()) :: boolean()
  def is_valid_access_token?(token) do
    case token do
      "xoxb-" <> _rest -> true
      _ -> false
    end
  end

  @spec get_default_access_token() :: binary() | nil
  def get_default_access_token() do
    token = System.get_env("SLACK_BOT_ACCESS_TOKEN")

    if is_valid_access_token?(token) do
      token
    else
      nil
    end
  end
end
