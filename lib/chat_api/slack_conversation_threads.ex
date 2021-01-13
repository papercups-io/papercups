defmodule ChatApi.SlackConversationThreads do
  @moduledoc """
  The SlackConversationThreads context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.SlackConversationThreads.SlackConversationThread

  @spec list_slack_conversation_threads(map()) :: [SlackConversationThread.t()]
  def list_slack_conversation_threads(filters \\ %{}) do
    SlackConversationThread
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec get_slack_conversation_thread!(binary()) :: SlackConversationThread.t()
  def get_slack_conversation_thread!(id), do: Repo.get!(SlackConversationThread, id)

  @spec get_thread_by_conversation_id(binary(), binary()) :: SlackConversationThread.t() | nil
  def get_thread_by_conversation_id(conversation_id, slack_channel) do
    SlackConversationThread
    |> where(conversation_id: ^conversation_id)
    |> where(slack_channel: ^slack_channel)
    |> preload(:conversation)
    |> Repo.one()
  end

  @spec get_threads_by_conversation_id(binary(), map()) :: [SlackConversationThread.t()]
  def get_threads_by_conversation_id(conversation_id, filters \\ %{}) do
    SlackConversationThread
    |> where(conversation_id: ^conversation_id)
    |> where(^filter_where(filters))
    |> preload(:conversation)
    |> Repo.all()
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
  def create_slack_conversation_thread(attrs \\ %{}) do
    %SlackConversationThread{}
    |> SlackConversationThread.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_slack_conversation_thread(SlackConversationThread.t(), map()) ::
          {:ok, SlackConversationThread.t()} | {:error, Ecto.Changeset.t()}
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
  def delete_slack_conversation_thread(%SlackConversationThread{} = slack_conversation_thread) do
    Repo.delete(slack_conversation_thread)
  end

  @spec change_slack_conversation_thread(SlackConversationThread.t(), map()) :: Ecto.Changeset.t()
  def change_slack_conversation_thread(
        %SlackConversationThread{} = slack_conversation_thread,
        attrs \\ %{}
      ) do
    SlackConversationThread.changeset(slack_conversation_thread, attrs)
  end

  @spec exists?(map()) :: boolean()
  def exists?(filters) do
    count =
      SlackConversationThread
      |> where(^filter_where(filters))
      |> select([t], count(t.id))
      |> Repo.one()

    count > 0
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map()) :: Ecto.Query.DynamicExpr.t()
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"slack_channel", value}, dynamic ->
        dynamic([r], ^dynamic and r.slack_channel == ^value)

      {"slack_thread_ts", value}, dynamic ->
        dynamic([r], ^dynamic and r.slack_thread_ts == ^value)

      {"account_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
