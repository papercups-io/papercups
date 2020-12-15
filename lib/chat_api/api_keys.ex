defmodule ChatApi.ApiKeys do
  @moduledoc """
  The ApiKeys context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.ApiKeys.PersonalApiKey

  @spec list_personal_api_keys(binary(), binary()) :: [PersonalApiKey.t()]
  def list_personal_api_keys(user_id, account_id) do
    PersonalApiKey
    |> where(user_id: ^user_id)
    |> where(account_id: ^account_id)
    |> Repo.all()
  end

  @spec get_personal_api_key!(binary()) :: PersonalApiKey.t()
  def get_personal_api_key!(id) do
    # TODO: filter by user_id/account_id?
    Repo.get!(PersonalApiKey, id)
  end

  @spec find_personal_api_key_by_value(binary()) :: PersonalApiKey.t() | nil
  def find_personal_api_key_by_value(value) do
    PersonalApiKey
    |> where(value: ^value)
    |> Repo.one()
    |> Repo.preload(:user)
  end

  @spec create_personal_api_key(map()) :: {:ok, PersonalApiKey.t()} | {:error, Ecto.Changeset.t()}
  def create_personal_api_key(attrs \\ %{}) do
    %PersonalApiKey{}
    |> PersonalApiKey.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_personal_api_key(PersonalApiKey.t(), map()) ::
          {:ok, PersonalApiKey.t()} | {:error, Ecto.Changeset.t()}
  def update_personal_api_key(%PersonalApiKey{} = personal_api_key, attrs) do
    personal_api_key
    |> PersonalApiKey.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_personal_api_key(PersonalApiKey.t()) ::
          {:ok, PersonalApiKey.t()} | {:error, Ecto.Changeset.t()}
  def delete_personal_api_key(%PersonalApiKey{} = personal_api_key) do
    Repo.delete(personal_api_key)
  end

  @spec change_personal_api_key(PersonalApiKey.t(), map()) :: Ecto.Changeset.t()
  def change_personal_api_key(%PersonalApiKey{} = personal_api_key, attrs \\ %{}) do
    PersonalApiKey.changeset(personal_api_key, attrs)
  end

  @spec generate_random_token(map()) :: binary()
  def generate_random_token(attrs \\ %{}) do
    case attrs do
      %{label: label, user_id: user_id, account_id: account_id} ->
        generate_random_token(label, user_id: user_id, account_id: account_id)

      %{"label" => label, "user_id" => user_id, "account_id" => account_id} ->
        generate_random_token(label, user_id: user_id, account_id: account_id)

      _ ->
        # TODO: should we return an error here?
        generate_random_token("API Key", [])
    end
  end

  @spec generate_random_token(binary(), any()) :: binary()
  def generate_random_token(label, data) do
    # TODO: figure out the best way to generate a random API token
    Phoenix.Token.sign(ChatApiWeb.Endpoint, label, data)
  end
end
