defmodule ChatApi.Workers.SendUserInvitationEmail do
  @moduledoc false

  use Oban.Worker, queue: :mailers

  alias ChatApi.{Accounts, Users}
  alias ChatApi.Repo

  require Logger

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{
        args: %{
          "user_id" => user_id,
          "account_id" => account_id,
          "to_address" => to_address,
          "invitation_token" => invitation_token
        }
      }) do
    if send_user_invitation_email_enabled?() do
      user = Users.find_by_id!(user_id) |> Repo.preload([:profile])
      account = Accounts.get_account!(account_id)
      Logger.info("Sending user invitation email to #{to_address}")

      deliver_result =
        ChatApi.Emails.send_user_invitation_email(
          user,
          account,
          to_address,
          invitation_token
        )

      case deliver_result do
        {:ok, result} ->
          Logger.info("Successfully sent user invitation email: #{inspect(result)}")

        {:warning, reason} ->
          Logger.warn("Warning when sending user invitation email: #{inspect(reason)}")

        {:error, reason} ->
          Logger.error("Error when sending user invitation email: #{inspect(reason)}")
      end
    else
      Logger.info("Skipping user invitation email to #{to_address}")
    end

    :ok
  end

  @spec send_user_invitation_email_enabled? :: boolean()
  def send_user_invitation_email_enabled?() do
    case System.get_env("USER_INVITATION_EMAIL_ENABLED") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
