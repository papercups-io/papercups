defmodule Mix.Tasks.GenerateApiKey do
  use Mix.Task

  @shortdoc "Generates an API key for the provided user/account"

  @moduledoc """
  This task generates an API key for the provided user/account

  Example:
  ```
  $ mix generate_api_key [YOUR_USER_ID] [YOUR_ACCOUNT_TOKEN]
  ```
  """

  def run(args) do
    Application.ensure_all_started(:chat_api)

    with [user_id, account_id] <- args,
         {:ok, _personal_api_key} <- generate_api_key(user_id, account_id) do
      Mix.shell().info(
        "Successfully generated API key for user #{inspect(user_id)} of account #{
          inspect(account_id)
        }"
      )
    else
      error -> Mix.shell().info("Failed to generate API key: #{inspect(error)}")
    end
  end

  defp generate_api_key(user_id, account_id) do
    attrs = %{
      user_id: user_id,
      account_id: account_id,
      label: "Test API Key"
    }

    token = ChatApi.ApiKeys.generate_random_token(attrs)

    %{value: token}
    |> Map.merge(attrs)
    |> ChatApi.ApiKeys.create_personal_api_key()
  end
end
