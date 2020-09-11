defmodule ChatApi.Customers do
  @moduledoc """
  The Customers context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Customers.Customer

  @doc """
  Returns the list of customers.

  ## Examples

      iex> list_customers(account_id)
      [%Customer{}, ...]

  """
  def list_customers(account_id) do
    Customer |> where(account_id: ^account_id) |> Repo.all()
  end

  @doc """
  Gets a single customer.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(123)
      %Customer{}

      iex> get_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(id), do: Repo.get!(Customer, id)

  def find_by_external_id(external_id, account_id) when is_binary(external_id) do
    Customer
    |> where(account_id: ^account_id, external_id: ^external_id)
    |> order_by(desc: :updated_at)
    |> first()
    |> Repo.one()
  end

  def find_by_external_id(external_id, account_id) when is_integer(external_id) do
    external_id |> to_string() |> find_by_external_id(account_id)
  end

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

  def update_customer_metadata(%Customer{} = customer, attrs) do
    customer
    |> Customer.metadata_changeset(attrs)
    |> Repo.update()
  end

  def sanitize_metadata(metadata) do
    case metadata do
      %{"external_id" => external_id} when is_integer(external_id) ->
        metadata
        |> Map.merge(%{"external_id" => to_string(external_id)})
        |> sanitize_metadata()

      _ ->
        metadata
    end
  end

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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end
end
