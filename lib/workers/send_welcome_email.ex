defmodule ChatApi.Workers.SendWelcomeEmail do
  use Oban.Worker, queue: :mailers

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => email}}) do
    # Only send the welcome email on the hosted version for now
    # (since the current email message is only relevant for hosted users)
    if System.get_env("BACKEND_URL") == "app.papercups.io" do
      Logger.info("Sending welcome email: #{email}")
      ChatApi.Emails.send_welcome_email(email)
    end

    :ok
  end
end
