defmodule ChatApi.SlackConversationThreads do
  @moduledoc """
  The SlackConversationThreads context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.SlackConversationThreads.SlackConversationThread

  @spec list_slack_conversation_threads() :: [SlackConversationThread.t()]
  @doc """
  Returns the list of slack_conversation_threads.

  ## Examples

      iex> list_slack_conversation_threads()
      [%SlackConversationThread{}, ...]

  """
  def list_slack_conversation_threads do
    Repo.all(SlackConversationThread)
  end

  @spec get_slack_conversation_thread!(binary()) :: SlackConversationThread.t()
  @doc """
  Gets a single slack_conversation_thread.

  Raises `Ecto.NoResultsError` if the Slack conversation thread does not exist.

  ## Examples

      iex> get_slack_conversation_thread!(123)
      %SlackConversationThread{}

      iex> get_slack_conversation_thread!(456)
      ** (Ecto.NoResultsError)

  """
  def get_slack_conversation_thread!(id), do: Repo.get!(SlackConversationThread, id)

  @spec get_thread_by_conversation_id(binary(), binary()) :: SlackConversationThread.t() | nil
  def get_thread_by_conversation_id(conversation_id, slack_channel) do
    SlackConversationThread
    |> where(conversation_id: ^conversation_id)
    |> where(slack_channel: ^slack_channel)
    |> preload(:conversation)
    |> Repo.one()
  end

  @spec get_by_slack_thread_ts(binary(), binary()) :: SlackConversationThread.t() | nil
  def get_by_slack_thread_ts(slack_thread_ts, slack_channel) do
    SlackConversationThread
    |> where(slack_thread_ts: ^slack_thread_ts)
    |> where(slack_channel: ^slack_channel)
    |> preload(:conversation)
    |> Repo.one()
  end

  @spec create_slack_conversation_thread(map()) ::
          {:ok, SlackConversationThread.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Creates a slack_conversation_thread.

  ## Examples

      iex> create_slack_conversation_thread(%{field: value})
      {:ok, %SlackConversationThread{}}

      iex> create_slack_conversation_thread(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_slack_conversation_thread(attrs \\ %{}) do
    %SlackConversationThread{}
    |> SlackConversationThread.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_slack_conversation_thread(SlackConversationThread.t(), map()) ::
          {:ok, SlackConversationThread.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a slack_conversation_thread.

  ## Examples

      iex> update_slack_conversation_thread(slack_conversation_thread, %{field: new_value})
      {:ok, %SlackConversationThread{}}

      iex> update_slack_conversation_thread(slack_conversation_thread, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_slack_conversation_thread(
        %SlackConversationThread{} = slack_conversation_thread,
        attrs
      ) do
    slack_conversation_thread
    |> SlackConversationThread.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_slack_conversation_thread(SlackConversationThread.t()) ::
          {:ok, SlackConversationThread.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes a slack_conversation_thread.

  ## Examples

      iex> delete_slack_conversation_thread(slack_conversation_thread)
      {:ok, %SlackConversationThread{}}

      iex> delete_slack_conversation_thread(slack_conversation_thread)
      {:error, %Ecto.Changeset{}}

  """
  def delete_slack_conversation_thread(%SlackConversationThread{} = slack_conversation_thread) do
    Repo.delete(slack_conversation_thread)
  end

  @spec change_slack_conversation_thread(SlackConverationThread.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking slack_conversation_thread changes.

  ## Examples

      iex> change_slack_conversation_thread(slack_conversation_thread)
      %Ecto.Changeset{data: %SlackConversationThread{}}

  """
  def change_slack_conversation_thread(
        %SlackConversationThread{} = slack_conversation_thread,
        attrs \\ %{}
      ) do
    SlackConversationThread.changeset(slack_conversation_thread, attrs)
  end
end
