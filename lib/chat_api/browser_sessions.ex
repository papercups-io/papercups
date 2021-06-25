defmodule ChatApi.BrowserSessions do
  @moduledoc """
  The BrowserSessions context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.BrowserSessions.BrowserSession

  @spec list_browser_sessions(binary(), map()) :: [BrowserSession.t()]
  def list_browser_sessions(account_id, filters \\ %{}) do
    limit = filters |> Map.get("limit", "100") |> String.to_integer()

    BrowserSession
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> order_by(desc: :updated_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:customer])
  end

  @spec count_browser_sessions(binary(), map()) :: number()
  def count_browser_sessions(account_id, filters \\ %{}) do
    BrowserSession
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> select([p], count(p.id))
    |> Repo.one()
  end

  @spec has_browser_sessions?(binary()) :: boolean
  def has_browser_sessions?(account_id), do: count_browser_sessions(account_id) > 0

  @doc """
  Gets a single browser_session.

  Raises `Ecto.NoResultsError` if the Browser session does not exist.

  ## Examples

      iex> get_browser_session!(123)
      %BrowserSession{}

      iex> get_browser_session!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_browser_session!(binary()) :: BrowserSession.t()
  def get_browser_session!(id) do
    BrowserSession |> Repo.get!(id) |> Repo.preload([:browser_replay_events, :customer])
  end

  @spec get_browser_session!(binary(), binary()) :: BrowserSession.t()
  def get_browser_session!(id, account_id) do
    BrowserSession
    |> where(id: ^id)
    |> where(account_id: ^account_id)
    |> Repo.one!()
    |> Repo.preload([:browser_replay_events, :customer])
  end

  @doc """
  Creates a browser_session.

  ## Examples

      iex> create_browser_session(%{field: value})
      {:ok, %BrowserSession{}}

      iex> create_browser_session(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_browser_session(attrs \\ %{}) do
    %BrowserSession{}
    |> BrowserSession.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a browser_session.

  ## Examples

      iex> update_browser_session(browser_session, %{field: new_value})
      {:ok, %BrowserSession{}}

      iex> update_browser_session(browser_session, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_browser_session(%BrowserSession{} = browser_session, attrs) do
    browser_session
    |> BrowserSession.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a browser_session.

  ## Examples

      iex> delete_browser_session(browser_session)
      {:ok, %BrowserSession{}}

      iex> delete_browser_session(browser_session)
      {:error, %Ecto.Changeset{}}

  """
  def delete_browser_session(%BrowserSession{} = browser_session) do
    Repo.delete(browser_session)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking browser_session changes.

  ## Examples

      iex> change_browser_session(browser_session)
      %Ecto.Changeset{data: %BrowserSession{}}

  """
  def change_browser_session(%BrowserSession{} = browser_session, attrs \\ %{}) do
    BrowserSession.changeset(browser_session, attrs)
  end

  def exists?(id) do
    count =
      BrowserSession
      |> where(id: ^id)
      |> select([p], count(p.id))
      |> Repo.one()

    count > 0
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"customer_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.customer_id == ^value)

      {"ids", list}, dynamic ->
        dynamic([p], ^dynamic and p.id in ^list)

      {"active", "true"}, dynamic ->
        dynamic([p], ^dynamic and is_nil(p.finished_at))

      {"active", "false"}, dynamic ->
        dynamic([p], ^dynamic and not is_nil(p.finished_at))

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
