defmodule ChatApi.Mattermost do
  @moduledoc """
  The Mattermost context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Mattermost.{
    MattermostAuthorization,
    MattermostConversationThread
  }

  #############################################################################
  # Mattermost authorizations
  #############################################################################

  @spec list_mattermost_authorizations() :: [MattermostAuthorization.t()]
  def list_mattermost_authorizations() do
    Repo.all(MattermostAuthorization)
  end

  @spec get_mattermost_authorization!(binary()) :: MattermostAuthorization.t()
  def get_mattermost_authorization!(id), do: Repo.get!(MattermostAuthorization, id)

  @spec create_mattermost_authorization(map()) ::
          {:ok, MattermostAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_mattermost_authorization(attrs \\ %{}) do
    %MattermostAuthorization{}
    |> MattermostAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_mattermost_authorization(MattermostAuthorization.t(), map()) ::
          {:ok, MattermostAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_mattermost_authorization(
        %MattermostAuthorization{} = mattermost_authorization,
        attrs
      ) do
    mattermost_authorization
    |> MattermostAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec create_or_update_authorization!(map()) ::
          {:ok, MattermostAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization!(attrs \\ %{}) do
    case attrs do
      %{"id" => id} when is_binary(id) ->
        id
        |> get_mattermost_authorization!()
        |> update_mattermost_authorization(attrs)

      params ->
        create_mattermost_authorization(params)
    end
  end

  @spec delete_mattermost_authorization(MattermostAuthorization.t()) ::
          {:ok, MattermostAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_mattermost_authorization(%MattermostAuthorization{} = mattermost_authorization) do
    Repo.delete(mattermost_authorization)
  end

  @spec change_mattermost_authorization(MattermostAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_mattermost_authorization(
        %MattermostAuthorization{} = mattermost_authorization,
        attrs \\ %{}
      ) do
    MattermostAuthorization.changeset(mattermost_authorization, attrs)
  end

  @spec get_authorization_by_account(binary(), map()) :: MattermostAuthorization.t() | nil
  def get_authorization_by_account(account_id, filters \\ %{}) do
    MattermostAuthorization
    |> where(account_id: ^account_id)
    |> where(^filter_authorizations_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @spec find_mattermost_authorization(map()) :: MattermostAuthorization.t() | nil
  def find_mattermost_authorization(filters \\ %{}) do
    MattermostAuthorization
    |> where(^filter_authorizations_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  defp filter_authorizations_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      # TODO: should inbox_id be a required field?
      {:inbox_id, nil}, dynamic ->
        dynamic([r], ^dynamic and is_nil(r.inbox_id))

      {:inbox_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.inbox_id == ^value)

      {:channel_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.channel_id == ^value)

      {:team_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.team_id == ^value)

      {:verification_token, value}, dynamic ->
        dynamic([r], ^dynamic and r.verification_token == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  #############################################################################
  # Mattermost conversation threads
  #############################################################################

  @spec list_mattermost_conversation_threads() :: [MattermostConversationThread.t()]
  def list_mattermost_conversation_threads() do
    Repo.all(MattermostConversationThread)
  end

  @spec get_mattermost_conversation_thread!(binary()) :: MattermostConversationThread.t()
  def get_mattermost_conversation_thread!(id), do: Repo.get!(MattermostConversationThread, id)

  @spec get_thread_by_conversation_id(binary()) :: MattermostConversationThread.t() | nil
  def get_thread_by_conversation_id(conversation_id) do
    MattermostConversationThread
    |> where(conversation_id: ^conversation_id)
    |> preload(:conversation)
    |> Repo.one()
  end

  @spec create_mattermost_conversation_thread(map()) ::
          {:ok, MattermostConversationThread.t()} | {:error, Ecto.Changeset.t()}
  def create_mattermost_conversation_thread(attrs \\ %{}) do
    %MattermostConversationThread{}
    |> MattermostConversationThread.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_mattermost_conversation_thread(MattermostConversationThread.t(), map()) ::
          {:ok, MattermostConversationThread.t()} | {:error, Ecto.Changeset.t()}
  def update_mattermost_conversation_thread(
        %MattermostConversationThread{} = mattermost_conversation_thread,
        attrs
      ) do
    mattermost_conversation_thread
    |> MattermostConversationThread.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_mattermost_conversation_thread(MattermostConversationThread.t()) ::
          {:ok, MattermostConversationThread.t()} | {:error, Ecto.Changeset.t()}
  def delete_mattermost_conversation_thread(
        %MattermostConversationThread{} = mattermost_conversation_thread
      ) do
    Repo.delete(mattermost_conversation_thread)
  end

  @spec change_mattermost_conversation_thread(MattermostConversationThread.t(), map()) ::
          Ecto.Changeset.t()
  def change_mattermost_conversation_thread(
        %MattermostConversationThread{} = mattermost_conversation_thread,
        attrs \\ %{}
      ) do
    MattermostConversationThread.changeset(mattermost_conversation_thread, attrs)
  end

  @spec find_mattermost_conversation_thread(map()) :: MattermostConversationThread.t() | nil
  def find_mattermost_conversation_thread(filters \\ %{}) do
    MattermostConversationThread
    |> where(^filter_conversation_threads_where(filters))
    |> order_by(desc: :inserted_at)
    |> preload(:conversation)
    |> first()
    |> Repo.one()
  end

  defp filter_conversation_threads_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:mattermost_channel_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.mattermost_channel_id == ^value)

      {:mattermost_post_root_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.mattermost_post_root_id == ^value)

      {:conversation_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.conversation_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
