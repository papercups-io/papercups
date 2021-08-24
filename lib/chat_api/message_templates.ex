defmodule ChatApi.MessageTemplates do
  @moduledoc """
  The MessageTemplates context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.MessageTemplates.MessageTemplate

  @spec list_message_templates(binary(), map()) :: [MessageTemplate.t()]
  def list_message_templates(account_id, filters \\ %{}) do
    MessageTemplate
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec get_message_template!(binary()) :: MessageTemplate.t()
  def get_message_template!(id), do: Repo.get!(MessageTemplate, id)

  @spec create_message_template(map()) ::
          {:ok, MessageTemplate.t()} | {:error, Ecto.Changeset.t()}
  def create_message_template(attrs \\ %{}) do
    %MessageTemplate{}
    |> MessageTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_message_template(MessageTemplate.t(), map()) ::
          {:ok, MessageTemplate.t()} | {:error, Ecto.Changeset.t()}
  def update_message_template(%MessageTemplate{} = message_template, attrs) do
    message_template
    |> MessageTemplate.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_message_template(MessageTemplate.t()) ::
          {:ok, MessageTemplate.t()} | {:error, Ecto.Changeset.t()}
  def delete_message_template(%MessageTemplate{} = message_template) do
    Repo.delete(message_template)
  end

  @spec change_message_template(MessageTemplate.t(), map()) :: Ecto.Changeset.t()
  def change_message_template(%MessageTemplate{} = message_template, attrs \\ %{}) do
    MessageTemplate.changeset(message_template, attrs)
  end

  @spec render(binary(), map()) :: {:ok, binary()} | {:error, any()}
  def render(content, data \\ %{}) do
    try do
      params = flatten_template_metadata(data)
      eex_params = Map.to_list(params)
      # TODO: just copy code from https://github.com/schultyy/Mustache.ex instead of using dep?
      result = content |> EEx.eval_string(eex_params) |> Mustache.render(params)

      {:ok, result}
    rescue
      e -> {:error, e}
    end
  end

  defp flatten_template_metadata(%{metadata: metadata} = data) when is_map(metadata),
    do: Map.merge(metadata, data)

  defp flatten_template_metadata(data) when is_map(data), do: data
  defp flatten_template_metadata(_), do: %{}

  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:name, value}, dynamic ->
        dynamic([r], ^dynamic and r.name == ^value)

      {:type, value}, dynamic ->
        dynamic([r], ^dynamic and r.type == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
