defmodule ChatApi.WidgetConfigs do
  @moduledoc """
  The WidgetConfigs context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.WidgetConfigs.WidgetConfig

  @doc """
  Returns the list of widget_configs.

  ## Examples

      iex> list_widget_configs()
      [%WidgetConfig{}, ...]

  """
  def list_widget_configs do
    Repo.all(WidgetConfig)
  end

  @doc """
  Gets a single widget_config.

  Raises `Ecto.NoResultsError` if the Widget config does not exist.

  ## Examples

      iex> get_widget_config!(123)
      %WidgetConfig{}

      iex> get_widget_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_widget_config!(id), do: Repo.get!(WidgetConfig, id)

  def create_or_update(nil, params) do
      create_widget_config(params)
  end

  def create_or_update(id, params) do
    existing = get_widget_config!(id)

    if existing do
      update_widget_config(existing, params)
    else
      create_widget_config(params)
    end
  end

  @doc """
  Creates a widget_config.

  ## Examples

      iex> create_widget_config(%{field: value})
      {:ok, %WidgetConfig{}}

      iex> create_widget_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_widget_config(attrs \\ %{}) do
    %WidgetConfig{}
    |> WidgetConfig.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a widget_config.

  ## Examples

      iex> update_widget_config(widget_config, %{field: new_value})
      {:ok, %WidgetConfig{}}

      iex> update_widget_config(widget_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_widget_config(%WidgetConfig{} = widget_config, attrs) do
    widget_config
    |> WidgetConfig.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a widget_config.

  ## Examples

      iex> delete_widget_config(widget_config)
      {:ok, %WidgetConfig{}}

      iex> delete_widget_config(widget_config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_widget_config(%WidgetConfig{} = widget_config) do
    Repo.delete(widget_config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking widget_config changes.

  ## Examples

      iex> change_widget_config(widget_config)
      %Ecto.Changeset{data: %WidgetConfig{}}

  """
  def change_widget_config(%WidgetConfig{} = widget_config, attrs \\ %{}) do
    WidgetConfig.changeset(widget_config, attrs)
  end
end
