defmodule ChatApi.Emails.CustomerIO do
  @moduledoc """
  A module to handle email automation with customer.io
  """

  require Logger

  # TODO: how should we handled disabled/archived users?

  @spec handle_registration_event(any(), any()) :: boolean()
  def handle_registration_event(user, company_name) do
    now = :os.system_time(:seconds)

    with {:ok, _} <-
           Customerio.identify(user.id, %{
             email: user.email,
             created_at: now,
             company_name: company_name
           }),
         {:ok, _} <- Customerio.track(user.id, "sign_up", %{signed_up_at: now}) do
      Logger.debug("Successfully added user to customer.io")

      true
    else
      error ->
        Logger.error("Something went wrong with customer.io: #{inspect(error)}")

        false
    end
  end

  @spec enabled?() :: boolean()
  def enabled?() do
    case System.get_env("CUSTOMER_IO_API_KEY") do
      key when is_binary(key) -> String.length(key) > 0
      _ -> false
    end
  end
end
