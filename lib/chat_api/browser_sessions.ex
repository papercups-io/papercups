defmodule ChatApi.BrowserSessions do
  @moduledoc """
  The BrowserSessions context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.BrowserSessions.BrowserSession

  @spec list_browser_sessions(binary()) :: [BrowserSession.t()]
  def list_browser_sessions(account_id) do
    BrowserSession |> where(account_id: ^account_id) |> Repo.all()
  end

  @doc """
  Gets a single browser_session.

  Raises `Ecto.NoResultsError` if the Browser session does not exist.

  ## Examples

      iex> get_browser_session!(123)
      %BrowserSession{}

      iex> get_browser_session!(456)
      ** (Ecto.NoResultsError)

  """
  def get_browser_session!(id), do: Repo.get!(BrowserSession, id)

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
end
