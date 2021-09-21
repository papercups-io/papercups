defmodule ChatApi.Twilio do
  @moduledoc """
  The Twilio context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Twilio.TwilioAuthorization

  @spec list_twilio_authorizations() :: [TwilioAuthorization.t()]
  def list_twilio_authorizations() do
    Repo.all(TwilioAuthorization)
  end

  @spec get_twilio_authorization!(binary()) :: TwilioAuthorization.t()
  def get_twilio_authorization!(id), do: Repo.get!(TwilioAuthorization, id)

  @spec create_twilio_authorization(map()) ::
          {:ok, TwilioAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_twilio_authorization(attrs \\ %{}) do
    %TwilioAuthorization{}
    |> TwilioAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_twilio_authorization(TwilioAuthorization.t(), map()) ::
          {:ok, TwilioAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_twilio_authorization(
        %TwilioAuthorization{} = twilio_authorization,
        attrs
      ) do
    twilio_authorization
    |> TwilioAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec create_or_update_authorization!(map()) ::
          {:ok, TwilioAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization!(attrs \\ %{}) do
    # TODO: should we take the "account_id" into account as well?
    case attrs do
      %{"id" => id} when is_binary(id) ->
        id
        |> get_twilio_authorization!()
        |> update_twilio_authorization(attrs)

      params ->
        create_twilio_authorization(params)
    end
  end

  @spec delete_twilio_authorization(TwilioAuthorization.t()) ::
          {:ok, TwilioAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_twilio_authorization(%TwilioAuthorization{} = twilio_authorization) do
    Repo.delete(twilio_authorization)
  end

  @spec change_twilio_authorization(TwilioAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_twilio_authorization(
        %TwilioAuthorization{} = twilio_authorization,
        attrs \\ %{}
      ) do
    TwilioAuthorization.changeset(twilio_authorization, attrs)
  end

  @spec get_authorization_by_account(binary(), map()) :: TwilioAuthorization.t() | nil
  def get_authorization_by_account(account_id, filters \\ %{}) do
    TwilioAuthorization
    |> where(account_id: ^account_id)
    |> where(^filter_authorizations_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @spec find_twilio_authorization(map()) :: TwilioAuthorization.t() | nil
  def find_twilio_authorization(filters \\ %{}) do
    TwilioAuthorization
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

      {:twilio_account_sid, value}, dynamic ->
        dynamic([r], ^dynamic and r.twilio_account_sid == ^value)

      {:from_phone_number, value}, dynamic ->
        dynamic([r], ^dynamic and r.from_phone_number == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
