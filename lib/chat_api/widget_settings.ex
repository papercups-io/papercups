defmodule ChatApi.WidgetSettings do
  @moduledoc """
  The WidgetSettings context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.WidgetSettings.WidgetSetting

  @spec list_widget_settings() :: [WidgetSetting.t()]
  @doc """
  Returns the list of widget_settings.

  ## Examples

      iex> list_widget_settings()
      [%WidgetSetting{}, ...]

  """
  def list_widget_settings do
    Repo.all(WidgetSetting)
  end

  @spec get_widget_setting!(binary()) :: WidgetSetting.t()
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

  @spec get_settings_by_account(binary()) :: WidgetSetting.t() | {:error, Ecto.Changeset.t()}
  def get_settings_by_account(account_id) do
    existing_settings =
      WidgetSetting
      |> where(account_id: ^account_id)
      |> preload(:account)
      |> Repo.one()

    case existing_settings do
      %WidgetSetting{} -> existing_settings
      nil -> create_setting_by_account(account_id)
    end
  end

  defp create_setting_by_account(account_id) do
    %WidgetSetting{}
    |> WidgetSetting.changeset(%{account_id: account_id})
    |> Repo.insert()
    |> case do
      {:ok, _settings} ->
        WidgetSetting
        |> where(account_id: ^account_id)
        |> preload(:account)
        |> Repo.one()

      error ->
        error
    end
  end

  @spec update_widget_setting(WidgetSettings.t(), map()) ::
          {:ok, WidgetSetting.t()} | {:error, Ecto.Changeset.t()}
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

  @spec update_widget_metadata(binary(), map()) ::
          {:ok, WidgetSetting.t()} | {:error, Ecto.Changeset.t()}
  def update_widget_metadata(account_id, metadata) do
    attrs = Map.take(metadata, ["host", "pathname", "last_seen_at"])

    get_settings_by_account(account_id)
    |> update_widget_setting(attrs)
  end

  @spec delete_widget_setting(WidgetSettings.t()) ::
          {:ok, WidgetSetting.t()} | {:error, Ecto.Changeset.t()}
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

  @spec change_widget_setting(WidgetSettings.t(), map()) :: Ecto.Changeset.t()
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
