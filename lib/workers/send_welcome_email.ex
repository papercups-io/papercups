defmodule ChatApi.Workers.SendWelcomeEmail do
  use Oban.Worker, queue: :mailers

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => email}}) do
    # Only send the welcome email on the hosted version for now
    # (since the current email message is only relevant for hosted users)
    # TODO: we should also probably come up with a less generic environment
    # variable name than "DOMAIN"... maybe "MAILGUN_DOMAIN"?
    if System.get_env("DOMAIN") == "mail.papercups.io" do
      Logger.info("Sending welcome email: #{email}")
      ChatApi.Emails.send_welcome_email(email)
    end

    :ok
  end
end
