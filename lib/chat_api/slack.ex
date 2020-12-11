defmodule ChatApi.Slack do
  @moduledoc """
  The Slack context
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.Slack.{SlackAuthorization, SlackConversationThread}

  @spec list_slack_authorizations() :: [SlackAuthorization.t()]
  def list_slack_authorizations do
    Repo.all(SlackAuthorization)
  end

  @spec get_slack_authorization!(binary()) :: SlackAuthorization.t()
  def get_slack_authorization!(id), do: Repo.get!(SlackAuthorization, id)

  @spec get_authorization_by_account(binary()) :: SlackAuthorization.t() | nil
  def get_authorization_by_account(account_id) do
    SlackAuthorization
    |> where(account_id: ^account_id)
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec create_or_update_authorization(binary(), map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization(account_id, params) do
    existing = get_authorization_by_account(account_id)

    if existing do
      update_slack_authorization(existing, params)
    else
      create_slack_authorization(params)
    end
  end

  @spec create_slack_authorization(map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_slack_authorization(attrs \\ %{}) do
    %SlackAuthorization{}
    |> SlackAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_slack_authorization(SlackAuthorization.t(), map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_slack_authorization(%SlackAuthorization{} = slack_authorization, attrs) do
    slack_authorization
    |> SlackAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_slack_authorization(SlackAuthorization.t()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_slack_authorization(%SlackAuthorization{} = slack_authorization) do
    Repo.delete(slack_authorization)
  end

  @spec change_slack_authorization(SlackAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_slack_authorization(%SlackAuthorization{} = slack_authorization, attrs \\ %{}) do
    SlackAuthorization.changeset(slack_authorization, attrs)
  end

  @spec list_slack_conversation_threads() :: [SlackConversationThread.t()]
  def list_slack_conversation_threads do
    Repo.all(SlackConversationThread)
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

  @spec change_slack_conversation_thread(SlackConverationThread.t(), map()) :: Ecto.Changeset.t()
  def change_slack_conversation_thread(
        %SlackConversationThread{} = slack_conversation_thread,
        attrs \\ %{}
      ) do
    SlackConversationThread.changeset(slack_conversation_thread, attrs)
  end
end
