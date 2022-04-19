defmodule ChatApi.WidgetSettings do
  @moduledoc """
  The WidgetSettings context.
  """

  require Logger

  import Ecto.Query, warn: false

  alias ChatApi.{Inboxes, Repo}
  alias ChatApi.WidgetSettings.WidgetSetting

  @spec list_widget_settings() :: [WidgetSetting.t()]
  def list_widget_settings do
    Repo.all(WidgetSetting)
  end

  @spec get_widget_setting!(binary()) :: WidgetSetting.t()
  def get_widget_setting!(id) do
    WidgetSetting |> preload(:account) |> Repo.get!(id)
  end

  @spec find_settings_by_account(binary(), map()) :: WidgetSetting.t() | nil
  def find_settings_by_account(account_id, filters \\ %{}) do
    WidgetSetting
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> preload(:account)
    |> Repo.one()
  end

  @spec get_settings_by_account!(binary(), map()) :: WidgetSetting.t()
  def get_settings_by_account!(account_id, filters \\ %{}) do
    case find_or_create_settings_by_account(account_id, filters) do
      {:ok, %WidgetSetting{} = settings} -> settings
      {:error, error} -> raise error
    end
  end

  @spec find_or_create_settings_by_account(binary(), map()) ::
          {:ok, WidgetSetting.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create_settings_by_account(account_id, filters \\ %{}) do
    case find_settings_by_account(account_id, filters) do
      %WidgetSetting{} = result ->
        {:ok, result}

      nil ->
        filters
        |> ensure_required_fields_included(account_id)
        |> create_widget_settings()
        |> case do
          {:ok, settings} -> {:ok, get_widget_setting!(settings.id)}
          error -> error
        end
    end
  end

  @spec create_widget_settings(map()) :: {:ok, WidgetSetting.t()} | {:error, Ecto.Changeset.t()}
  def create_widget_settings(attrs \\ %{}) do
    %WidgetSetting{}
    |> WidgetSetting.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_widget_setting(WidgetSetting.t(), map()) ::
          {:ok, WidgetSetting.t()} | {:error, Ecto.Changeset.t()}
  def update_widget_setting(%WidgetSetting{} = widget_setting, attrs) do
    widget_setting
    |> WidgetSetting.changeset(attrs)
    |> Repo.update()
  end

  @spec update_widget_metadata(binary(), map(), map()) ::
          {:ok, WidgetSetting.t()} | {:error, Ecto.Changeset.t()}
  def update_widget_metadata(account_id, metadata, filters \\ %{}) do
    attrs = Map.take(metadata, ["host", "pathname", "last_seen_at"])

    account_id
    |> get_settings_by_account!(filters)
    |> update_widget_setting(attrs)
  end

  @spec delete_widget_setting(WidgetSetting.t()) ::
          {:ok, WidgetSetting.t()} | {:error, Ecto.Changeset.t()}
  def delete_widget_setting(%WidgetSetting{} = widget_setting) do
    Repo.delete(widget_setting)
  end

  @spec change_widget_setting(WidgetSetting.t(), map()) :: Ecto.Changeset.t()
  def change_widget_setting(%WidgetSetting{} = widget_setting, attrs \\ %{}) do
    WidgetSetting.changeset(widget_setting, attrs)
  end

  @spec ensure_required_fields_included(map(), binary()) :: map()
  defp ensure_required_fields_included(params, account_id) do
    case params do
      %{"inbox_id" => inbox_id} when is_binary(inbox_id) ->
        Map.merge(params, %{"account_id" => account_id, "inbox_id" => inbox_id})

      _ ->
        Map.merge(params, %{
          "account_id" => account_id,
          "inbox_id" => Inboxes.get_account_primary_inbox_id(account_id)
        })
    end
  end

  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"account_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      # TODO: should inbox_id be a required field?
      {"inbox_id", nil}, dynamic ->
        dynamic([r], ^dynamic and is_nil(r.inbox_id))

      {"inbox_id", value}, dynamic ->
        dynamic([r], ^dynamic and r.inbox_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
