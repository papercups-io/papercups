defmodule Mix.Tasks.UpdateCustomerIo do
  use Mix.Task
  require Logger
  import Ecto.Query, warn: false
  alias ChatApi.Repo

  @shortdoc "Updates user data in customer.io"

  @moduledoc """
  This task syncs latest user data with customer.io
  """

  def run(_args) do
    Application.ensure_all_started(:chat_api)

    if ChatApi.Emails.CustomerIO.enabled?() do
      list_valid_users() |> update_customer_io_users()

      Mix.shell().info("Updated users in customer.io!")
    end
  end

  def update_customer_io_users(users) do
    for user <- users do
      # TODO: only execute in production
      case ChatApi.Emails.CustomerIO.identify(user.id, user) do
        {:ok, _} -> Logger.info("Successfully updated user #{inspect(user.id)}")
        error -> Logger.error("Error updating user #{inspect(user.id)}: #{inspect(error)}")
      end
    end
  end

  def query_valid_users() do
    ChatApi.Users.User
    |> join(:left, [u], a in assoc(u, :account))
    |> join(:left, [u], p in assoc(u, :profile))
    |> where([u], is_nil(u.disabled_at) and is_nil(u.archived_at))
    |> where([u], u.has_valid_email == true)
    |> order_by([u], desc: u.inserted_at)
    |> select([u, a, p], {u, a, p})
  end

  def list_valid_users() do
    query_valid_users()
    |> Repo.all()
    |> Enum.map(fn {user, account, profile} ->
      format_user!(user, account, profile)
    end)
  end

  def get_most_recent_message(user) do
    user_id = user.id

    ChatApi.Messages.Message
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def format_user!(user, account) do
    # TODO: use a struct here?
    %{
      # User fields
      id: user.id,
      email: user.email,
      account_id: user.account_id,
      role: user.role,
      # Account fields
      company_name: account.company_name,
      plan: account.subscription_plan,
      # Timestamps
      created_at: format_ts!(user.inserted_at),
      updated_at: format_ts!(user.updated_at),
      last_message_sent_at: format_last_message_sent_at!(user)
    }
  end

  def format_user!(user, account, %{full_name: full_name, display_name: display_name}) do
    full_name = full_name || display_name || ""
    [first_name | _] = String.split(full_name, " ")

    user
    |> format_user!(account)
    |> Map.merge(%{full_name: full_name, first_name: first_name})
  end

  def format_user!(user, account, _) do
    user
    |> format_user!(account)
    |> Map.merge(%{full_name: nil, first_name: nil})
  end

  def format_last_message_sent_at!(user) do
    case get_most_recent_message(user) do
      %{sent_at: sent_at} when not is_nil(sent_at) -> format_ts!(sent_at)
      %{inserted_at: inserted_at} when not is_nil(inserted_at) -> format_ts!(inserted_at)
      _ -> nil
    end
  end

  def format_ts!(date) do
    date |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
  end
end
