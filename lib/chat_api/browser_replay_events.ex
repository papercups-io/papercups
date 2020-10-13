defmodule ChatApi.BrowserReplayEvents do
  @moduledoc """
  The BrowserReplayEvents context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.BrowserReplayEvents.BrowserReplayEvent

  @doc """
  Returns the list of browser_replay_events.

  ## Examples

      iex> list_browser_replay_events(account_id)
      [%BrowserReplayEvent{}, ...]

  """
  @spec list_browser_replay_events(binary()) :: [BrowserReplayEvent.t()]
  def list_browser_replay_events(account_id) do
    BrowserReplayEvent |> where(account_id: ^account_id) |> Repo.all()
  end

  @doc """
  Gets a single browser_replay_event.

  Raises `Ecto.NoResultsError` if the Browser replay event does not exist.

  ## Examples

      iex> get_browser_replay_event!(123)
      %BrowserReplayEvent{}

      iex> get_browser_replay_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_browser_replay_event!(id), do: Repo.get!(BrowserReplayEvent, id)

  @doc """
  Creates a browser_replay_event.

  ## Examples

      iex> create_browser_replay_event(%{field: value})
      {:ok, %BrowserReplayEvent{}}

      iex> create_browser_replay_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_browser_replay_event(attrs \\ %{}) do
    %BrowserReplayEvent{}
    |> BrowserReplayEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a browser_replay_event.

  ## Examples

      iex> update_browser_replay_event(browser_replay_event, %{field: new_value})
      {:ok, %BrowserReplayEvent{}}

      iex> update_browser_replay_event(browser_replay_event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_browser_replay_event(%BrowserReplayEvent{} = browser_replay_event, attrs) do
    browser_replay_event
    |> BrowserReplayEvent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a browser_replay_event.

  ## Examples

      iex> delete_browser_replay_event(browser_replay_event)
      {:ok, %BrowserReplayEvent{}}

      iex> delete_browser_replay_event(browser_replay_event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_browser_replay_event(%BrowserReplayEvent{} = browser_replay_event) do
    Repo.delete(browser_replay_event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking browser_replay_event changes.

  ## Examples

      iex> change_browser_replay_event(browser_replay_event)
      %Ecto.Changeset{data: %BrowserReplayEvent{}}

  """
  def change_browser_replay_event(%BrowserReplayEvent{} = browser_replay_event, attrs \\ %{}) do
    BrowserReplayEvent.changeset(browser_replay_event, attrs)
  end
end
