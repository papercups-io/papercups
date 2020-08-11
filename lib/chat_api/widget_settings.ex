defmodule ChatApi.WidgetSettings do
  @moduledoc """
  The WidgetSettings context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.WidgetSettings.WidgetSetting

  @doc """
  Returns the list of widget_settings.

  ## Examples

      iex> list_widget_settings()
      [%WidgetSetting{}, ...]

  """
  def list_widget_settings do
    Repo.all(WidgetSetting)
  end

  @doc """
  Gets a single widget_setting.

  Raises `Ecto.NoResultsError` if the Widget config does not exist.

  ## Examples

      iex> get_widget_setting!(123)
      %WidgetSetting{}

      iex> get_widget_setting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_widget_setting!(id), do: Repo.get!(WidgetSetting, id)

  def get_settings_by_account(account_id) do
    WidgetSetting
    |> where(account_id: ^account_id)
    |> preload(:account)
    |> Repo.one()
  end

  def create_or_update(nil, params) do
    create_widget_setting(params)
  end

  def create_or_update(account_id, params) do
    existing = get_settings_by_account(account_id)

    if existing do
      update_widget_setting(existing, params)
    else
      create_widget_setting(params)
    end
  end

  @doc """
  Creates a widget_setting.

  ## Examples

      iex> create_widget_setting(%{field: value})
      {:ok, %WidgetSetting{}}

      iex> create_widget_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_widget_setting(attrs \\ %{}) do
    %WidgetSetting{}
    |> WidgetSetting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a widget_setting.

  ## Examples

      iex> update_widget_setting(widget_setting, %{field: new_value})
      {:ok, %WidgetSetting{}}

      iex> update_widget_setting(widget_setting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_widget_setting(%WidgetSetting{} = widget_setting, attrs) do
    widget_setting
    |> WidgetSetting.changeset(attrs)
    |> Repo.update()
  end

  def update_widget_metadata(account_id, metadata) do
    attrs = Map.take(metadata, ["host", "pathname", "last_seen_at"])
    {:ok, settings} = create_or_update(account_id, %{account_id: account_id})

    update_widget_setting(settings, attrs)
  end

  @doc """
  Deletes a widget_setting.

  ## Examples

      iex> delete_widget_setting(widget_setting)
      {:ok, %WidgetSetting{}}

      iex> delete_widget_setting(widget_setting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_widget_setting(%WidgetSetting{} = widget_setting) do
    Repo.delete(widget_setting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking widget_setting changes.

  ## Examples

      iex> change_widget_setting(widget_setting)
      %Ecto.Changeset{data: %WidgetSetting{}}

  """
  def change_widget_setting(%WidgetSetting{} = widget_setting, attrs \\ %{}) do
    WidgetSetting.changeset(widget_setting, attrs)
  end
end
