defmodule ChatApi.Emails.CustomerIO do
  @moduledoc """
  A module to handle email automation with customer.io
  """

  alias ChatApi.Users
  require Logger

  # TODO: how should we handled disabled/archived users?

  @spec handle_registration_event(any(), any()) :: boolean()
  def handle_registration_event(user, company_name) do
    case Users.validate_email(user) do
      {:ok, %Users.User{has_valid_email: true} = user} ->
        save_new_signup(user, company_name)

      _ ->
        Logger.warn("Unable to validate user's email. Skipping save to Customer IO.")

        false
    end
  end

  @spec identify(any(), any()) :: {:error, Customerio.Error.t()} | {:ok, binary()}
  def identify(user_id, attrs \\ %{}) do
    if enabled?() do
      Customerio.identify(user_id, attrs)
    else
      msg = "Would have identified user #{inspect(user_id)} with data: #{inspect(attrs)}"
      Logger.info("[Customer IO] #{msg}")

      {:ok, msg}
    end
  end

  @spec track(any(), binary(), any()) :: {:error, Customerio.Error.t()} | {:ok, binary()}
  def track(user_id, event, attrs \\ %{}) do
    if enabled?() do
      Customerio.track(user_id, event, attrs)
    else
      msg =
        "Would have tracked event #{inspect(event)} " <>
          "for user #{inspect(user_id)} " <>
          "with data: #{inspect(attrs)}"

      Logger.info("[Customer IO] #{msg}")

      {:ok, msg}
    end
  end

  @spec enabled?() :: boolean()
  def enabled?() do
    case System.get_env("CUSTOMER_IO_API_KEY") do
      key when is_binary(key) -> String.length(key) > 0
      _ -> false
    end
  end

  @spec save_new_signup(Users.User.t(), binary()) :: boolean()
  defp save_new_signup(user, company_name) do
    now = :os.system_time(:seconds)

    with {:ok, _} <-
           identify(user.id, %{
             email: user.email,
             created_at: now,
             company_name: company_name
           }),
         {:ok, _} <- track(user.id, "sign_up", %{signed_up_at: now}) do
      Logger.debug("Successfully added user to customer.io")

      true
    else
      error ->
        Logger.error("Something went wrong with customer.io: #{inspect(error)}")

        false
    end
  end
end
