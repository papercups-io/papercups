defmodule ChatApi.Customers do
  @moduledoc """
  The Customers context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Customers.Customer
  alias ChatApi.Tags.CustomerTag

  @spec list_customers(binary(), map()) :: [Customer.t()]
  def list_customers(account_id, filters \\ %{}) do
    Customer
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec list_customers(binary(), map(), map()) :: Scrivener.Page.t()
  @doc """
  Returns a `%Scrivener.Page{}` with paginated customers.

  ## Examples
      iex> list_customers(account_id, %{}, %{})
      %Scrivener.Page{entries: [%Customer{},...], page_size: 50}

      iex> list_customers(account_id, %{"company_id" => "xxxxx"}, %{page_size: 10, page: 2})
      %Scrivener.Page{entries: [%Customer{},...], page_size: 10, page: 2}

  """
  def list_customers(account_id, filters, pagination_params) do
    Customer
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.paginate(pagination_params)
  end

  @spec get_customer!(binary()) :: Customer.t() | nil
  def get_customer!(id) do
    Customer |> Repo.get!(id) |> Repo.preload(:tags)
  end

  @spec find_by_external_id(binary(), binary(), map()) :: Customer.t() | nil
  def find_by_external_id(external_id, account_id, filters \\ %{})

  def find_by_external_id(external_id, account_id, filters) when is_binary(external_id) do
    Customer
    |> where(account_id: ^account_id, external_id: ^external_id)
    |> where(^filter_where(filters))
    |> order_by(desc: :updated_at)
    |> first()
    |> Repo.one()
  end

  @spec find_by_external_id(integer(), binary(), map()) :: Customer.t() | nil
  def find_by_external_id(external_id, account_id, filters) when is_integer(external_id) do
    external_id |> to_string() |> find_by_external_id(account_id, filters)
  end

  @spec find_by_email(binary() | nil, binary()) :: Customer.t() | nil
  def find_by_email(nil, _account_id), do: nil

  def find_by_email(email, account_id) do
    Customer
    |> where(account_id: ^account_id, email: ^email)
    |> order_by(desc: :updated_at)
    |> first()
    |> Repo.one()
  end

  @spec find_or_create_by_email(binary() | nil, binary(), map()) ::
          {:ok, Customer.t()} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def find_or_create_by_email(email, account_id, attrs \\ %{})
  def find_or_create_by_email(nil, _account_id, _attrs), do: {:error, :email_required}

  def find_or_create_by_email(email, account_id, attrs) do
    case find_by_email(email, account_id) do
      nil ->
        %{
          # Defaults
          first_seen: DateTime.utc_now(),
          last_seen: DateTime.utc_now(),
          # TODO: last_seen is stored as a date, while last_seen_at is stored as
          # a datetime -- we should opt for datetime values whenever possible
          last_seen_at: DateTime.utc_now()
        }
        |> Map.merge(attrs)
        |> Map.merge(%{email: email, account_id: account_id})
        |> create_customer()

      customer ->
        {:ok, customer}
    end
  end

  @spec create_or_update_by_email(binary() | nil, binary(), map()) ::
          {:ok, Customer.t()} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def create_or_update_by_email(email, account_id, attrs \\ %{})
  def create_or_update_by_email(nil, _account_id, _attrs), do: {:error, :email_required}

  def create_or_update_by_email(email, account_id, attrs) do
    case find_by_email(email, account_id) do
      nil ->
        %{
          # Defaults
          first_seen: DateTime.utc_now(),
          last_seen: DateTime.utc_now(),
          # TODO: last_seen is stored as a date, while last_seen_at is stored as
          # a datetime -- we should opt for datetime values whenever possible
          last_seen_at: DateTime.utc_now()
        }
        |> Map.merge(attrs)
        |> Map.merge(%{email: email, account_id: account_id})
        |> create_customer()

      customer ->
        update_customer(customer, attrs)
    end
  end

  @spec create_customer(map()) :: {:ok, Customer.t()} | {:error, Ecto.Changeset.t()}
  def create_customer(attrs \\ %{}) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_customer(Customer.t(), map) :: {:ok, Customer.t()} | {:error, Ecto.Changeset.t()}
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
  def delete_customer(%Customer{} = customer) do
    Repo.delete(customer)
  end

  @spec change_customer(Customer.t(), map()) :: Ecto.Changeset.t()
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

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  def filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"company_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.company_id == ^value)

      {"name", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.name, ^value))

      {"email", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.email, ^value))

      {"host", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.host, ^value))

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
