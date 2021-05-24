defmodule ChatApi.Google do
  @moduledoc """
  The Google context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Accounts, Emails, Repo}
  alias ChatApi.Google.{GoogleAuthorization, GmailConversationThread}

  #############################################################################
  # Google authorizations
  #############################################################################

  @spec list_google_authorizations() :: [GoogleAuthorization.t()]
  def list_google_authorizations(filters \\ %{}) do
    GoogleAuthorization
    |> where(^filter_authorizations_where(filters))
    |> Repo.all()
  end

  @spec get_google_authorization!(binary()) :: GoogleAuthorization.t()
  def get_google_authorization!(id), do: Repo.get!(GoogleAuthorization, id)

  @spec create_google_authorization(map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_google_authorization(attrs \\ %{}) do
    %GoogleAuthorization{}
    |> GoogleAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_google_authorization(GoogleAuthorization.t(), map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_google_authorization(%GoogleAuthorization{} = google_authorization, attrs) do
    google_authorization
    |> GoogleAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_google_authorization(GoogleAuthorization.t()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_google_authorization(%GoogleAuthorization{} = google_authorization) do
    Repo.delete(google_authorization)
  end

  @spec change_google_authorization(GoogleAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_google_authorization(%GoogleAuthorization{} = google_authorization, attrs \\ %{}) do
    GoogleAuthorization.changeset(google_authorization, attrs)
  end

  @spec get_authorization_by_account(binary(), map()) :: GoogleAuthorization.t() | nil
  def get_authorization_by_account(account_id, filters \\ %{}) do
    GoogleAuthorization
    |> where(account_id: ^account_id)
    |> where(^filter_authorizations_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  def get_personal_gmail_authorization(account_id, user_id),
    do:
      get_authorization_by_account(account_id, %{
        client: "gmail",
        type: "personal",
        user_id: user_id
      })

  def get_support_gmail_authorization(account_id, _user_id),
    do: get_support_gmail_authorization(account_id)

  def get_support_gmail_authorization(account_id),
    do:
      get_authorization_by_account(account_id, %{
        client: "gmail",
        type: "support"
      })

  @spec get_default_gmail_authorization(binary(), integer()) :: GoogleAuthorization.t() | nil
  def get_default_gmail_authorization(account_id, user_id) do
    case get_personal_gmail_authorization(account_id, user_id) do
      %GoogleAuthorization{} = auth -> auth
      nil -> get_authorization_by_account(account_id, %{client: "gmail"})
    end
  end

  @spec create_or_update_authorization(binary(), map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization(account_id, params) do
    existing = get_authorization_by_account(account_id, params)

    if existing do
      update_google_authorization(existing, params)
    else
      create_google_authorization(params)
    end
  end

  @spec format_sender_display_name(GoogleAuthorization.t(), integer(), binary()) :: binary()
  def format_sender_display_name(%GoogleAuthorization{type: "personal"}, user_id, account_id),
    do: Emails.format_sender_name(user_id, account_id)

  def format_sender_display_name(_, _, account_id) do
    account = Accounts.get_account!(account_id)

    "#{account.company_name} Team"
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_authorizations_where(map) :: %Ecto.Query.DynamicExpr{}
  defp filter_authorizations_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:client, value}, dynamic ->
        dynamic([g], ^dynamic and g.client == ^value)

      {:scope, value}, dynamic ->
        dynamic([g], ^dynamic and g.scope == ^value)

      {:type, value}, dynamic ->
        dynamic([g], ^dynamic and g.type == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  #############################################################################
  # Gmail conversation threads
  #############################################################################

  @spec list_gmail_conversation_threads() :: [GmailConversationThread.t()]
  def list_gmail_conversation_threads() do
    Repo.all(GmailConversationThread)
  end

  @spec get_gmail_conversation_thread!(binary()) :: GmailConversationThread.t()
  def get_gmail_conversation_thread!(id), do: Repo.get!(GmailConversationThread, id)

  @spec get_thread_by_conversation_id(binary()) :: GmailConversationThread.t() | nil
  def get_thread_by_conversation_id(conversation_id) do
    GmailConversationThread
    |> where(conversation_id: ^conversation_id)
    |> preload(:conversation)
    |> Repo.one()
  end

  @spec create_gmail_conversation_thread(map()) ::
          {:ok, GmailConversationThread.t()} | {:error, Ecto.Changeset.t()}
  def create_gmail_conversation_thread(attrs \\ %{}) do
    %GmailConversationThread{}
    |> GmailConversationThread.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_gmail_conversation_thread(GmailConversationThread.t(), map()) ::
          {:ok, GmailConversationThread.t()} | {:error, Ecto.Changeset.t()}
  def update_gmail_conversation_thread(
        %GmailConversationThread{} = gmail_conversation_thread,
        attrs
      ) do
    gmail_conversation_thread
    |> GmailConversationThread.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_gmail_conversation_thread(GmailConversationThread.t()) ::
          {:ok, GmailConversationThread.t()} | {:error, Ecto.Changeset.t()}
  def delete_gmail_conversation_thread(%GmailConversationThread{} = gmail_conversation_thread) do
    Repo.delete(gmail_conversation_thread)
  end

  @spec change_gmail_conversation_thread(GmailConversationThread.t(), map()) ::
          Ecto.Changeset.t()
  def change_gmail_conversation_thread(
        %GmailConversationThread{} = gmail_conversation_thread,
        attrs \\ %{}
      ) do
    GmailConversationThread.changeset(gmail_conversation_thread, attrs)
  end

  @spec find_gmail_conversation_thread(map()) :: GmailConversationThread.t() | nil
  def find_gmail_conversation_thread(filters \\ %{}) do
    GmailConversationThread
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

      {:gmail_thread_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.gmail_thread_id == ^value)

      {:conversation_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.conversation_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
