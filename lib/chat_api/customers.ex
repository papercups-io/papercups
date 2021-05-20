defmodule ChatApi.Customers do
  @moduledoc """
  The Customers context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Conversations
  alias ChatApi.Customers.Customer
  alias ChatApi.Issues.CustomerIssue
  alias ChatApi.Tags.CustomerTag

  @spec list_customers(binary(), map()) :: [Customer.t()]
  def list_customers(account_id, filters \\ %{}) do
    Customer
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> filter_by_tags(filters)
    |> filter_by_tag(filters)
    |> filter_by_issue(filters)
    |> order_by(desc: :last_seen_at)
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
    conversations_query = Conversations.query_most_recent_conversation(partition_by: :customer_id)

    Customer
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> filter_by_tag(filters)
    |> filter_by_tags(filters)
    |> filter_by_issue(filters)
    |> order_by(desc: :last_seen_at)
    |> preload(conversations: ^conversations_query)
    |> Repo.paginate(pagination_params)
  end

  @spec filter_by_tag(Ecto.Query.t(), map()) :: Ecto.Query.t()
  def filter_by_tag(query, %{"tag_id" => tag_id}) when not is_nil(tag_id) do
    query
    |> join(:left, [c], t in assoc(c, :tags))
    |> where([_c, t], t.id == ^tag_id)
  end

  def filter_by_tag(query, _filters), do: query

  @spec filter_by_tags(Ecto.Query.t(), map()) :: Ecto.Query.t()
  def filter_by_tags(query, %{"tag_ids" => tag_ids}) when not is_nil(tag_ids) do
    # We need to return a query that includes only the customers that are tagged with the passed in tag_ids.

    # Here, we aggregate the number of tags each customer has, but we only count the ones included in tag_ids.
    # Essentially, we're querying the number of tag_ids each customer has.
    customer_tags_query =
      from(ct in CustomerTag,
        where: ct.tag_id in ^tag_ids,
        group_by: ct.customer_id,
        select: %{customer_id: ct.customer_id, tag_count: count(ct.tag_id)}
      )

    # Because tag_count represents the number of tag_ids each customer has,
    # we're able to join the two query and filter only the customers that
    # have exactly the same number of tag_ids.
    from(c in query,
      join: ct in subquery(customer_tags_query),
      on: c.id == ct.customer_id,
      where: ct.tag_count == ^length(tag_ids)
    )
  end

  def filter_by_tags(query, _filters), do: query

  @spec filter_by_issue(Ecto.Query.t(), map()) :: Ecto.Query.t()
  def filter_by_issue(query, %{"issue_id" => issue_id}) when not is_nil(issue_id) do
    query
    |> join(:left, [c], t in assoc(c, :issues))
    |> where([_c, t], t.id == ^issue_id)
  end

  def filter_by_issue(query, _filters), do: query

  @spec get_customer!(binary(), atom() | list(atom()) | keyword()) :: Customer.t()
  def get_customer!(id, preloads \\ [:company, :tags]) do
    Customer
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @spec is_valid_association?(atom()) :: boolean()
  def is_valid_association?(field) do
    Enum.any?(
      [
        :messages,
        :conversations,
        :notes,
        :tags,
        :company,
        :issues
      ],
      fn association -> association == field end
    )
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

  @spec find_or_create_by_external_id(binary() | nil, binary(), map()) ::
          {:ok, Customer.t()} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def find_or_create_by_external_id(external_id, account_id, attrs \\ %{})
  def find_or_create_by_external_id(nil, _account_id, _attrs), do: {:error, :external_id_required}

  def find_or_create_by_external_id(external_id, account_id, attrs) do
    case find_by_external_id(external_id, account_id) do
      nil ->
        get_default_params()
        |> Map.merge(attrs)
        |> Map.merge(%{external_id: external_id, account_id: account_id})
        |> create_customer()

      customer ->
        {:ok, customer}
    end
  end

  def find_by_phone(phone, account_id, filters \\ %{}) do
    Customer
    |> where(account_id: ^account_id, phone: ^phone)
    |> where(^filter_where(filters))
    |> order_by(desc: :updated_at)
    |> first()
    |> Repo.one()
  end

  @spec find_or_create_by_phone(binary() | nil, binary(), map()) ::
          {:ok, Customer.t()} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def find_or_create_by_phone(phone, account_id, attrs \\ %{})
  def find_or_create_by_phone(nil, _account_id, _attrs), do: {:error, :phone_required}

  def find_or_create_by_phone(phone, account_id, attrs) do
    case find_by_phone(phone, account_id) do
      nil ->
        get_default_params()
        |> Map.merge(attrs)
        |> Map.merge(%{phone: phone, account_id: account_id})
        |> create_customer()

      customer ->
        {:ok, customer}
    end
  end

  @spec create_or_update_by_external_id(binary() | nil, binary(), map()) ::
          {:ok, Customer.t()} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def create_or_update_by_external_id(external_id, account_id, attrs \\ %{})

  def create_or_update_by_external_id(nil, _account_id, _attrs),
    do: {:error, :external_id_required}

  def create_or_update_by_external_id(external_id, account_id, attrs) do
    case find_by_external_id(external_id, account_id) do
      nil ->
        get_default_params()
        |> Map.merge(attrs)
        |> Map.merge(%{external_id: external_id, account_id: account_id})
        |> create_customer()

      customer ->
        update_customer(customer, attrs)
    end
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
        get_default_params()
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
        get_default_params()
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

  # Ideally these would be set at the DB level, but this should be fine for now
  @spec get_default_params(map()) :: map()
  def get_default_params(overrides \\ %{}) do
    Map.merge(
      %{
        # Defaults
        first_seen: DateTime.utc_now(),
        last_seen_at: DateTime.utc_now()
      },
      overrides
    )
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

  @spec get_issue(Customer.t(), binary()) :: nil | CustomerIssue.t()
  def get_issue(%Customer{id: id, account_id: account_id} = _customer, issue_id) do
    CustomerIssue
    |> where(account_id: ^account_id, customer_id: ^id, issue_id: ^issue_id)
    |> Repo.one()
  end

  @spec link_issue(Customer.t(), binary()) ::
          {:ok, CustomerIssue.t()} | {:error, Ecto.Changeset.t()}
  def link_issue(%Customer{id: id, account_id: account_id} = customer, issue_id) do
    case get_issue(customer, issue_id) do
      nil ->
        %CustomerIssue{}
        |> CustomerIssue.changeset(%{
          customer_id: id,
          issue_id: issue_id,
          account_id: account_id
        })
        |> Repo.insert()

      issue ->
        {:ok, issue}
    end
  end

  @spec unlink_issue(Customer.t(), binary()) ::
          {:ok, CustomerIssue.t()} | {:error, Ecto.Changeset.t()}
  def unlink_issue(%Customer{} = customer, issue_id) do
    customer
    |> get_issue(issue_id)
    |> Repo.delete()
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"company_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.company_id == ^value)

      {"account_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {"external_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.external_id == ^value)

      {"browser_version", value}, dynamic ->
        dynamic([r], ^dynamic and r.browser_version == ^value)

      {"browser_language", value}, dynamic ->
        dynamic([r], ^dynamic and r.browser_language == ^value)

      {"name", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.name, ^value))

      {"email", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.email, ^value))

      {"phone", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.phone, ^value))

      {"host", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.host, ^value))

      {"browser", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.browser, ^value))

      {"os", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.os, ^value))

      {"current_url", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.current_url, ^value))

      {"pathname", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.pathname, ^value))

      {"time_zone", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.time_zone, ^value))

      {"include_anonymous", "false"}, dynamic ->
        dynamic([r], ^dynamic and not is_nil(r.email))

      {"q", ""}, dynamic ->
        dynamic

      {"q", query}, dynamic ->
        dynamic([r], ^dynamic and ^filter_by_query(query))

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  defp filter_by_query(query) do
    query
    |> String.split(" ")
    |> Enum.reduce(dynamic(true), fn
      word, dynamic ->
        case String.split(word, ":") do
          [key, value] ->
            dynamic([r], ^dynamic and fragment("(metadata->>? = ?)", ^key, ^value))

          [word] ->
            value = "%" <> word <> "%"

            dynamic([r], ^dynamic and (ilike(r.email, ^value) or ilike(r.name, ^value)))
        end
    end)
  end
end
