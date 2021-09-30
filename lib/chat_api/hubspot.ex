defmodule ChatApi.Hubspot do
  @moduledoc """
  The Hubspot context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Hubspot.HubspotAuthorization

  @spec list_hubspot_authorizations() :: [HubspotAuthorization.t()]
  def list_hubspot_authorizations() do
    Repo.all(HubspotAuthorization)
  end

  @spec get_hubspot_authorization!(binary()) :: HubspotAuthorization.t()
  def get_hubspot_authorization!(id), do: Repo.get!(HubspotAuthorization, id)

  @spec create_hubspot_authorization(map()) ::
          {:ok, HubspotAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_hubspot_authorization(attrs \\ %{}) do
    %HubspotAuthorization{}
    |> HubspotAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_hubspot_authorization(HubspotAuthorization.t(), map()) ::
          {:ok, HubspotAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_hubspot_authorization(
        %HubspotAuthorization{} = hubspot_authorization,
        attrs
      ) do
    hubspot_authorization
    |> HubspotAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec create_or_update_authorization(map()) ::
          {:ok, HubspotAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization(%{account_id: account_id} = attrs) do
    case get_authorization_by_account(account_id) do
      %HubspotAuthorization{} = authorization ->
        update_hubspot_authorization(authorization, attrs)

      nil ->
        create_hubspot_authorization(attrs)
    end
  end

  @spec delete_hubspot_authorization(HubspotAuthorization.t()) ::
          {:ok, HubspotAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_hubspot_authorization(%HubspotAuthorization{} = hubspot_authorization) do
    Repo.delete(hubspot_authorization)
  end

  @spec change_hubspot_authorization(HubspotAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_hubspot_authorization(
        %HubspotAuthorization{} = hubspot_authorization,
        attrs \\ %{}
      ) do
    HubspotAuthorization.changeset(hubspot_authorization, attrs)
  end

  @spec get_authorization_by_account(binary(), map()) :: HubspotAuthorization.t() | nil
  def get_authorization_by_account(account_id, _filters \\ %{}) do
    HubspotAuthorization
    |> where(account_id: ^account_id)
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @spec find_hubspot_authorization(map()) :: HubspotAuthorization.t() | nil
  def find_hubspot_authorization(filters \\ %{}) do
    HubspotAuthorization
    |> where(^filter_authorizations_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  defp filter_authorizations_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:scope, value}, dynamic ->
        dynamic([r], ^dynamic and r.scope == ^value)

      {:token_type, value}, dynamic ->
        dynamic([r], ^dynamic and r.token_type == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
