defmodule ChatApi.EventSubscriptions do
  @moduledoc """
  The EventSubscriptions context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.EventSubscriptions.EventSubscription

  @spec list_event_subscriptions(binary()) :: [EventSubscription.t()]
  @doc """
  Returns the list of event_subscriptions.

  ## Examples

      iex> list_event_subscriptions(account_id)
      [%EventSubscription{}, ...]

  """
  def list_event_subscriptions(account_id) do
    EventSubscription |> where(account_id: ^account_id) |> Repo.all()
  end

  @spec list_verified_event_subscriptions(binary()) :: [EventSubscription.t()]
  def list_verified_event_subscriptions(account_id) do
    EventSubscription
    |> where(account_id: ^account_id)
    |> where(verified: true)
    |> Repo.all()
  end

  @spec get_event_subscription!(binary()) :: EventSubscription.t() | nil
  @doc """
  Gets a single event_subscription.

  Raises `Ecto.NoResultsError` if the Event subscription does not exist.

  ## Examples

      iex> get_event_subscription!(123)
      %EventSubscription{}

      iex> get_event_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_subscription!(id), do: Repo.get!(EventSubscription, id)

  @spec create_event_subscription(map()) ::
          {:ok, EventSubscription.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Creates a event_subscription.

  ## Examples

      iex> create_event_subscription(%{field: value})
      {:ok, %EventSubscription{}}

      iex> create_event_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event_subscription(attrs \\ %{}) do
    %EventSubscription{}
    |> EventSubscription.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_event_subscription(EventSubscription.t(), map()) ::
          {:ok, EventSubscription.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a event_subscription.

  ## Examples

      iex> update_event_subscription(event_subscription, %{field: new_value})
      {:ok, %EventSubscription{}}

      iex> update_event_subscription(event_subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event_subscription(%EventSubscription{} = event_subscription, attrs) do
    event_subscription
    |> EventSubscription.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_event_subscription(EventSubscription.t()) ::
          {:ok, EventSubscription.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes a event_subscription.

  ## Examples

      iex> delete_event_subscription(event_subscription)
      {:ok, %EventSubscription{}}

      iex> delete_event_subscription(event_subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event_subscription(%EventSubscription{} = event_subscription) do
    Repo.delete(event_subscription)
  end

  @spec change_event_subscription(EventSubscription.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event_subscription changes.

  ## Examples

      iex> change_event_subscription(event_subscription)
      %Ecto.Changeset{data: %EventSubscription{}}

  """
  def change_event_subscription(%EventSubscription{} = event_subscription, attrs \\ %{}) do
    EventSubscription.changeset(event_subscription, attrs)
  end

  @spec notify_event_subscriptions(binary(), map()) :: [Tesla.Env.result()]
  def notify_event_subscriptions(account_id, event) do
    account_id
    |> list_verified_event_subscriptions()
    |> Enum.map(fn sub ->
      notify_webhook_url(sub.webhook_url, event)
    end)
  end

  @spec notify_webhook_url(binary(), map()) :: Tesla.Env.result()
  def notify_webhook_url(url, event) do
    [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"content-type", "application/json"}]}
    ]
    |> Tesla.client()
    |> Tesla.post(url, event)
  end

  @spec is_valid_uri?(binary() | URI.t()) :: boolean()
  def is_valid_uri?(str) do
    case URI.parse(str) do
      %URI{scheme: nil} -> false
      %URI{host: nil} -> false
      %URI{path: nil} -> false
      _uri -> true
    end
  end

  @spec is_valid_webhook_url?(binary() | URI.t()) :: boolean()
  def is_valid_webhook_url?(url) do
    if is_valid_uri?(url) do
      # Generate random string (TODO: maybe this should be its own utility method)
      challenge = :crypto.strong_rand_bytes(64) |> Base.encode32() |> binary_part(0, 64)
      event = %{"event" => "webhook:verify", "payload" => challenge}

      case notify_webhook_url(url, event) do
        {:ok, %{body: body}} ->
          verify_webhook_challenge(body, challenge)

        _ ->
          false
      end
    else
      false
    end
  end

  defp verify_webhook_challenge(body, challenge) do
    case body do
      %{"challenge" => json} -> json == challenge
      str -> str == challenge
    end
  end
end
