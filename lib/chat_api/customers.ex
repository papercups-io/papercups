defmodule ChatApi.Customers do
  @moduledoc """
  The Customers context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Customers.Customer
  alias ChatApi.Tags.CustomerTag

  @spec list_customers(binary()) :: [Customer.t()]
  @doc """
  Returns the list of customers.

  ## Examples

      iex> list_customers(account_id)
      [%Customer{}, ...]

  """
  def list_customers(account_id) do
    Customer |> where(account_id: ^account_id) |> Repo.all()
  end

  @spec get_customer!(binary()) :: Customer.t() | nil
  @doc """
  Gets a single customer.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(123)
      %Customer{}

      iex> get_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(id) do
    Customer |> Repo.get!(id) |> Repo.preload(:tags)
  end

  @spec find_by_external_id(binary(), binary()) :: Customer.t() | nil
  def find_by_external_id(external_id, account_id) when is_binary(external_id) do
    Customer
    |> where(account_id: ^account_id, external_id: ^external_id)
    |> order_by(desc: :updated_at)
    |> first()
    |> Repo.one()
  end

  @spec find_by_external_id(integer(), binary()) :: Customer.t() | nil
  def find_by_external_id(external_id, account_id) when is_integer(external_id) do
    external_id |> to_string() |> find_by_external_id(account_id)
  end

  @spec create_customer(map()) :: {:ok, Customer.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Creates a customer.

  ## Examples

      iex> create_customer(%{field: value})
      {:ok, %Customer{}}

      iex> create_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(attrs \\ %{}) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_customer(Customer.t(), map) :: {:ok, Customer.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a customer.

  ## Examples

      iex> update_customer(customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update_customer(customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end

  @spec update_customer_metadata(Customer.t(), map()) ::
          {:ok, Customer.t()} | {:error, Ecto.Changeset.t()}
  def update_customer_metadata(%Customer{} = customer, attrs) do
    customer
    |> Customer.metadata_changeset(attrs)
    |> Repo.update()
  end

  # TODO: figure out if any of this can be done in the changeset, or if there's
  # a better way to handle this in general
  @spec sanitize_metadata(map()) :: map()
  def sanitize_metadata(metadata) do
    metadata
    |> sanitize_metadata_external_id()
    |> sanitize_metadata_current_url()
    |> sanitize_ad_hoc_metadata()
  end

  @spec sanitize_metadata_external_id(map()) :: map()
  def sanitize_metadata_external_id(%{"external_id" => external_id} = metadata)
      when is_integer(external_id) do
    Map.merge(metadata, %{"external_id" => to_string(external_id)})
  end

  def sanitize_metadata_external_id(metadata), do: metadata

  @spec sanitize_metadata_current_url(map()) :: map()
  def sanitize_metadata_current_url(%{"current_url" => current_url} = metadata) do
    if String.length(current_url) > 255 do
      # Ensure `current_url` is never longer than 255 characters
      # (TODO: maybe just support longer urls in the future?)
      Map.merge(metadata, %{"current_url" => String.slice(current_url, 0, 250) <> "..."})
    else
      metadata
    end
  end

  def sanitize_metadata_current_url(metadata), do: metadata

  @spec sanitize_ad_hoc_metadata(map()) :: map()
  def sanitize_ad_hoc_metadata(%{"metadata" => meta} = metadata) when not is_map(meta) do
    # If the ad hoc metadata is invalid (i.e. not a map), just delete it
    Map.delete(metadata, "metadata")
  end

  def sanitize_ad_hoc_metadata(metadata), do: metadata

  @spec delete_customer(Customer.t()) :: {:ok, Customer.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes a customer.

  ## Examples

      iex> delete_customer(customer)
      {:ok, %Customer{}}

      iex> delete_customer(customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_customer(%Customer{} = customer) do
    Repo.delete(customer)
  end

  @spec change_customer(Customer.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end

  @spec exists?(binary()) :: boolean()
  def exists?(id) do
    count =
      Customer
      |> where(id: ^id)
      |> select([p], count(p.id))
      |> Repo.one()

    count > 0
  end

  @spec list_tags(nil | binary() | Customer.t()) :: nil | [Tag.t()]
  def list_tags(nil), do: []

  def list_tags(%Customer{} = customer) do
    customer |> Repo.preload(:tags) |> Map.get(:tags)
  end

  def list_tags(id) do
    # TODO: optimize this query
    Customer
    |> Repo.get(id)
    |> case do
      nil -> []
      found -> found |> Repo.preload(:tags) |> Map.get(:tags)
    end
  end

  @spec get_tag(Customer.t(), binary()) :: nil | CustomerTag.t()
  def get_tag(%Customer{id: id, account_id: account_id} = _customer, tag_id) do
    CustomerTag
    |> where(account_id: ^account_id, customer_id: ^id, tag_id: ^tag_id)
    |> Repo.one()
  end

  @spec add_tag(Customer.t(), binary()) :: {:ok, CustomerTag.t()} | {:error, Ecto.Changeset.t()}
  def add_tag(%Customer{id: id, account_id: account_id} = customer, tag_id) do
    case get_tag(customer, tag_id) do
      nil ->
        %CustomerTag{}
        |> CustomerTag.changeset(%{
          customer_id: id,
          tag_id: tag_id,
          account_id: account_id
        })
        |> Repo.insert()

      tag ->
        {:ok, tag}
    end
  end

  @spec remove_tag(Customer.t(), binary()) ::
          {:ok, CustomerTag.t()} | {:error, Ecto.Changeset.t()}
  def remove_tag(%Customer{} = customer, tag_id) do
    customer
    |> get_tag(tag_id)
    |> Repo.delete()
  end
end
