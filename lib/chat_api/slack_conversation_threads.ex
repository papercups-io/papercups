defmodule ChatApi.SlackConversationThreads do
  @moduledoc """
  The SlackConversationThreads context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.{Repo, Slack, SlackAuthorizations}
  alias ChatApi.SlackConversationThreads.SlackConversationThread
  alias ChatApi.SlackAuthorizations.SlackAuthorization

  @spec list_slack_conversation_threads(map()) :: [SlackConversationThread.t()]
  def list_slack_conversation_threads(filters \\ %{}) do
    SlackConversationThread
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec list_slack_conversation_threads_by_account(map()) :: [SlackConversationThread.t()]
  def list_slack_conversation_threads_by_account(account_id, filters \\ %{}) do
    SlackConversationThread
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
    |> Enum.map(fn thread ->
      thread
      |> Map.merge(%{permalink: get_slack_conversation_thread_permalink(thread)})
      |> Map.merge(%{slack_channel_name: get_slack_conversation_thread_channel_name(thread)})
    end)
  end

  @spec get_slack_conversation_thread!(binary()) :: SlackConversationThread.t()
  def get_slack_conversation_thread!(id), do: Repo.get!(SlackConversationThread, id)

  @spec get_latest_slack_conversation_thread(map()) :: SlackConversationThread.t() | nil
  def get_latest_slack_conversation_thread(filters \\ %{}) do
    SlackConversationThread
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

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

  @spec find_matching_slack_authorization(SlackConversationThread.t()) ::
          SlackAuthorization.t() | nil
  def find_matching_slack_authorization(%SlackConversationThread{
        account_id: account_id,
        slack_channel: slack_channel_id
      }) do
    authorizations = SlackAuthorizations.list_slack_authorizations_by_account(account_id)
    match = Enum.find(authorizations, fn auth -> auth.channel_id == slack_channel_id end)

    # If a match was found with a valid access token, use that; otherwise, check for a "support" type authorization
    case match do
      %SlackAuthorization{access_token: access_token} = auth when not is_nil(access_token) -> auth
      _ -> Enum.find(authorizations, fn auth -> auth.type == "support" end)
    end
  end

  @spec has_slack_reply_authorization?(SlackConversationThread.t()) :: boolean()
  def has_slack_reply_authorization?(%SlackConversationThread{} = thread) do
    case find_matching_slack_authorization(thread) do
      %SlackAuthorization{type: "reply"} -> true
      _ -> false
    end
  end

  @spec get_slack_conversation_thread_channel_name(SlackConversationThread.t()) :: binary() | nil
  def get_slack_conversation_thread_channel_name(
        %SlackConversationThread{
          slack_channel: channel
        } = slack_conversation_thread
      ) do
    with %{access_token: access_token} <-
           find_matching_slack_authorization(slack_conversation_thread),
         {:ok, response} <- Slack.Client.retrieve_channel_info(channel, access_token),
         %{body: %{"channel" => %{"name" => slack_channel_name}}} <- response do
      slack_channel_name
    else
      error ->
        Logger.info(
          "Could not get channel name for Slack thread #{inspect(slack_conversation_thread)} -- #{inspect(error)}"
        )

        nil
    end
  end

  @spec get_slack_conversation_thread_permalink(SlackConversationThread.t()) :: binary() | nil
  def get_slack_conversation_thread_permalink(
        %SlackConversationThread{
          slack_channel: channel,
          slack_thread_ts: ts
        } = slack_conversation_thread
      ) do
    with %{access_token: access_token} <-
           find_matching_slack_authorization(slack_conversation_thread),
         {:ok, response} <- Slack.Client.get_message_permalink(channel, ts, access_token),
         %{body: %{"permalink" => permalink}} <- response do
      permalink
    else
      error ->
        Logger.info(
          "Could not get permalink for Slack thread #{inspect(slack_conversation_thread)} -- #{inspect(error)}"
        )

        nil
    end
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map()) :: %Ecto.Query.DynamicExpr{}
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"slack_channel", value}, dynamic ->
        dynamic([r], ^dynamic and r.slack_channel == ^value)

      {"slack_thread_ts", value}, dynamic ->
        dynamic([r], ^dynamic and r.slack_thread_ts == ^value)

      {"account_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {"conversation_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.conversation_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
