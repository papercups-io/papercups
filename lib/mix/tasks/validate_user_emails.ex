defmodule Mix.Tasks.ValidateUserEmails do
  use Mix.Task
  require Logger
  import Ecto.Query, warn: false
  alias ChatApi.Repo

  @shortdoc "Validates user emails with debounce.io"

  @moduledoc """
  This task checks for users that have not had their emails validated yet, and
  uses the debounce.io API to perform a validation.

  It also accepts as args a list of emails that are known to be valid.

  Ex: $ mix validate_user_emails $(cat path/to/emails.csv)
  """

  def run(args) do
    Application.ensure_all_started(:chat_api)

    handle_known_emails(args)
    validate_unknown_emails()

    Mix.shell().info("Finished marking user email validity!")
  end

  def handle_known_emails(emails \\ []) do
    Logger.info("Handling known emails: #{inspect(emails)}")

    emails
    |> Enum.filter(fn email -> ChatApi.Emails.Helpers.valid_format?(email) end)
    |> Enum.map(fn email ->
      email
      |> ChatApi.Users.find_user_by_email()
      |> case do
        nil -> nil
        user -> ChatApi.Users.set_has_valid_email(user, true)
      end
    end)
  end

  def retrieve_users_without_validation() do
    ChatApi.Users.User |> where([u], is_nil(u.has_valid_email)) |> Repo.all()
  end

  def validate_unknown_emails() do
    retrieve_users_without_validation()
    |> Enum.map(fn user ->
      ChatApi.Users.set_has_valid_email(user, has_valid_email?(user))
    end)
  end

  def has_valid_email?(%{email: email}) do
    Logger.info("Validating email: #{inspect(email)}")

    ChatApi.Emails.Debounce.enabled?() &&
      !ChatApi.Emails.Debounce.disposable?(email) &&
      ChatApi.Emails.Debounce.valid?(email)
  end
end
