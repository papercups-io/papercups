defmodule ChatApi.Mattermost.Helpers do
  @moduledoc """
  Utility methods for interacting with Mattermost
  """

  alias ChatApi.{Mattermost, Users}
  alias ChatApi.Mattermost.MattermostAuthorization
  alias ChatApi.Users.User

  @spec find_matching_user(MattermostAuthorization.t(), binary()) :: User.t() | nil
  def find_matching_user(
        %MattermostAuthorization{account_id: account_id} = authorization,
        mattermost_user_id
      ) do
    case Mattermost.Client.get_user(mattermost_user_id, authorization) do
      {:ok, %{body: %{"email" => email}}} -> Users.find_user_by_email(email, account_id)
      _ -> nil
    end
  end

  @spec mattermost_ts_to_utc(binary() | nil) :: DateTime.t()
  def mattermost_ts_to_utc(nil), do: DateTime.utc_now()

  def mattermost_ts_to_utc(ts) do
    case DateTime.from_unix(ts, :millisecond) do
      {:ok, datetime} -> datetime
      _ -> DateTime.utc_now()
    end
  end
end
