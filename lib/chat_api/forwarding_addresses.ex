defmodule ChatApi.ForwardingAddresses do
  @moduledoc """
  The ForwardingAddresses context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Repo, Accounts}
  alias ChatApi.Accounts.Account
  alias ChatApi.ForwardingAddresses.ForwardingAddress

  @spec list_forwarding_addresses(binary(), map()) :: [ForwardingAddress.t()]
  def list_forwarding_addresses(account_id, filters \\ %{}) do
    ForwardingAddress
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec count_forwarding_addresses(binary(), map()) :: number()
  def count_forwarding_addresses(account_id, filters \\ %{}) do
    ForwardingAddress
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> select([f], count(f.id))
    |> Repo.one()
  end

  @spec has_forwarding_addresses?(binary()) :: boolean()
  def has_forwarding_addresses?(account_id),
    do: count_forwarding_addresses(account_id) > 0

  @spec get_forwarding_address!(binary()) :: ForwardingAddress.t()
  def get_forwarding_address!(id), do: Repo.get!(ForwardingAddress, id)

  @spec find_by_forwarding_email(binary()) :: ForwardingAddress.t() | nil
  def find_by_forwarding_email(email) do
    ForwardingAddress
    |> where(forwarding_email_address: ^email)
    |> Repo.one()
  end

  @spec find_account_by_forwarding_address(binary()) :: Account.t() | nil
  def find_account_by_forwarding_address(email) do
    case find_by_forwarding_email(email) do
      %ForwardingAddress{account_id: account_id} ->
        Accounts.get_account!(account_id)

      nil ->
        nil
    end
  end

  @spec find_by_source_email(binary()) :: ForwardingAddress.t() | nil
  def find_by_source_email(email) do
    ForwardingAddress
    |> where(source_email_address: ^email)
    |> Repo.one()
  end

  @spec find_account_by_source_address(binary()) :: Account.t() | nil
  def find_account_by_source_address(email) do
    case find_by_source_email(email) do
      %ForwardingAddress{account_id: account_id} ->
        Accounts.get_account!(account_id)

      nil ->
        nil
    end
  end

  @spec create_forwarding_address(map()) ::
          {:ok, ForwardingAddress.t()} | {:error, Ecto.Changeset.t()}
  def create_forwarding_address(attrs \\ %{}) do
    %ForwardingAddress{}
    |> ForwardingAddress.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_forwarding_address(ForwardingAddress.t(), map()) ::
          {:ok, ForwardingAddress.t()} | {:error, Ecto.Changeset.t()}
  def update_forwarding_address(%ForwardingAddress{} = forwarding_address, attrs) do
    forwarding_address
    |> ForwardingAddress.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_forwarding_address(ForwardingAddress.t()) ::
          {:ok, ForwardingAddress.t()} | {:error, Ecto.Changeset.t()}
  def delete_forwarding_address(%ForwardingAddress{} = forwarding_address) do
    Repo.delete(forwarding_address)
  end

  @spec change_forwarding_address(ForwardingAddress.t(), map()) :: Ecto.Changeset.t()
  def change_forwarding_address(%ForwardingAddress{} = forwarding_address, attrs \\ %{}) do
    ForwardingAddress.changeset(forwarding_address, attrs)
  end

  def generate_forwarding_email_address(domain) do
    prefix =
      :crypto.strong_rand_bytes(32)
      |> Base.encode32()
      |> binary_part(0, 32)
      |> String.downcase()

    "#{prefix}@#{domain}"
  end

  def generate_forwarding_email_address() do
    domain = Application.get_env(:chat_api, :ses_forwarding_domain, "chat.papercups.io")

    generate_forwarding_email_address(domain)
  end

  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"account_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      # TODO: should inbox_id be a required field?
      {"inbox_id", nil}, dynamic ->
        dynamic([r], ^dynamic and is_nil(r.inbox_id))

      {"inbox_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.inbox_id == ^value)

      {"forwarding_email_address", value}, dynamic ->
        dynamic([r], ^dynamic and r.forwarding_email_address == ^value)

      {"source_email_address", value}, dynamic ->
        dynamic([r], ^dynamic and r.source_email_address == ^value)

      {"state", value}, dynamic ->
        dynamic([r], ^dynamic and r.state == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
