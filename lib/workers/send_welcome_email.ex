defmodule ChatApi.Workers.SendWelcomeEmail do
  @moduledoc false

  use Oban.Worker, queue: :mailers

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => email}}) do
    # Only send the welcome email on the hosted version for now
    # (since the current email message is only relevant for hosted users)
    # TODO: we should also probably come up with a less generic environment
    # variable name than "DOMAIN"... maybe "MAILGUN_DOMAIN"?
    if is_hosted_version?() && welcome_email_enabled?() do
      Logger.info("Sending welcome email: #{email}")
      ChatApi.Emails.send_welcome_email(email)
    else
      Logger.info("Skipping welcome email: #{email}")
    end

    :ok
  end

  def is_hosted_version?() do
    System.get_env("DOMAIN") == "mail.heypapercups.io"
  end

  def welcome_email_enabled?() do
    case System.get_env("WELCOME_EMAIL_ENABLED") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
