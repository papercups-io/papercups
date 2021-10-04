defmodule ChatApi.Intercom do
  @moduledoc """
  The Intercom context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.Intercom.IntercomAuthorization

  @spec list_intercom_authorizations() :: [IntercomAuthorization.t()]
  def list_intercom_authorizations() do
    Repo.all(IntercomAuthorization)
  end

  @spec get_intercom_authorization!(binary()) :: IntercomAuthorization.t()
  def get_intercom_authorization!(id), do: Repo.get!(IntercomAuthorization, id)

  @spec create_intercom_authorization(map()) ::
          {:ok, IntercomAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_intercom_authorization(attrs \\ %{}) do
    %IntercomAuthorization{}
    |> IntercomAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_intercom_authorization(IntercomAuthorization.t(), map()) ::
          {:ok, IntercomAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_intercom_authorization(
        %IntercomAuthorization{} = intercom_authorization,
        attrs
      ) do
    intercom_authorization
    |> IntercomAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec create_or_update_authorization(map()) ::
          {:ok, IntercomAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization(%{account_id: account_id} = attrs) do
    case get_authorization_by_account(account_id) do
      %IntercomAuthorization{} = authorization ->
        update_intercom_authorization(authorization, attrs)

      nil ->
        create_intercom_authorization(attrs)
    end
  end

  @spec delete_intercom_authorization(IntercomAuthorization.t()) ::
          {:ok, IntercomAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_intercom_authorization(%IntercomAuthorization{} = intercom_authorization) do
    Repo.delete(intercom_authorization)
  end

  @spec change_intercom_authorization(IntercomAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_intercom_authorization(
        %IntercomAuthorization{} = intercom_authorization,
        attrs \\ %{}
      ) do
    IntercomAuthorization.changeset(intercom_authorization, attrs)
  end

  @spec get_authorization_by_account(binary(), map()) :: IntercomAuthorization.t() | nil
  def get_authorization_by_account(account_id, filters \\ %{}) do
    IntercomAuthorization
    |> where(account_id: ^account_id)
    |> where(^filter_authorizations_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @spec find_intercom_authorization(map()) :: IntercomAuthorization.t() | nil
  def find_intercom_authorization(filters \\ %{}) do
    IntercomAuthorization
    |> where(^filter_authorizations_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  defp filter_authorizations_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:token_type, value}, dynamic ->
        dynamic([r], ^dynamic and r.token_type == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
