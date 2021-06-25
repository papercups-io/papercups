defmodule ChatApi.Lambdas do
  @moduledoc """
  The Lambdas context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Lambdas.Lambda

  @spec list_lambdas(binary(), map()) :: [Lambda.t()]
  def list_lambdas(account_id, filters \\ %{}) do
    Lambda
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec get_lambda!(binary()) :: Lambda.t()
  def get_lambda!(id), do: Repo.get!(Lambda, id)

  @spec create_lambda(map()) :: {:ok, Lambda.t()} | {:error, Ecto.Changeset.t()}
  def create_lambda(attrs \\ %{}) do
    %Lambda{}
    |> Lambda.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_lambda(Lambda.t(), map()) :: {:ok, Lambda.t()} | {:error, Ecto.Changeset.t()}
  def update_lambda(%Lambda{} = lambda, attrs) do
    lambda
    |> Lambda.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_lambda(Lambda.t()) :: {:ok, Lambda.t()} | {:error, Ecto.Changeset.t()}
  def delete_lambda(%Lambda{} = lambda) do
    Repo.delete(lambda)
  end

  @spec change_lambda(Lambda.t(), map()) :: Ecto.Changeset.t()
  def change_lambda(%Lambda{} = lambda, attrs \\ %{}) do
    Lambda.changeset(lambda, attrs)
  end

  @spec deploy(Lambda.t(), map()) :: {:ok, Lambda.t()} | {:error, any()}
  def deploy(%Lambda{} = lambda, opts \\ %{}) do
    result =
      case lambda do
        %Lambda{code: nil} ->
          # TODO: how should we handle deploys if there is no code?
          nil

        %Lambda{lambda_function_name: lambda_function_name, code: code}
        when is_binary(lambda_function_name) ->
          ChatApi.Aws.update_lambda_function_config(lambda_function_name, opts)
          ChatApi.Aws.update_function_by_code(code, lambda_function_name, opts)

        %Lambda{name: name, lambda_function_name: _, code: code} ->
          lambda_function_name = ChatApi.Aws.generate_unique_filename(name)

          ChatApi.Aws.create_function_by_code(code, lambda_function_name, opts)
      end

    case result do
      %{"FunctionName" => function_name} ->
        update_lambda(lambda, %{
          lambda_function_name: function_name,
          last_deployed_at: DateTime.utc_now(),
          status:
            case lambda.status do
              "pending" -> "inactive"
              status -> status
            end
        })

      error ->
        {:error, error}
    end
  end

  @spec deploy_file(Lambda.t(), Plug.Upload.t(), map()) :: {:ok, Lambda.t()} | {:error, any()}
  def deploy_file(%Lambda{} = lambda, %Plug.Upload{} = file, opts \\ %{}) do
    result =
      case lambda do
        %Lambda{lambda_function_name: lambda_function_name}
        when is_binary(lambda_function_name) ->
          ChatApi.Aws.update_lambda_function_config(lambda_function_name, opts)
          ChatApi.Aws.update_function_by_file(file.path, lambda_function_name, opts)

        %Lambda{name: name, lambda_function_name: _} ->
          lambda_function_name = ChatApi.Aws.generate_unique_filename(name)

          ChatApi.Aws.create_function_by_file(file.path, lambda_function_name, opts)
      end

    case result do
      %{"FunctionName" => function_name} ->
        update_lambda(lambda, %{
          lambda_function_name: function_name,
          last_deployed_at: DateTime.utc_now(),
          status:
            case lambda.status do
              "pending" -> "inactive"
              status -> status
            end
        })

      error ->
        {:error, error}
    end
  end

  @spec invoke(Lambda.t(), map()) :: {:ok, any()} | {:error, any()}
  def invoke(%Lambda{} = lambda, payload \\ %{}) do
    case lambda do
      %Lambda{lambda_function_name: lambda_function_name}
      when is_binary(lambda_function_name) ->
        {:ok, ChatApi.Aws.invoke_lambda_function(lambda_function_name, payload)}

      %Lambda{lambda_function_name: _} ->
        {:error, :missing_function_name}
    end
  end

  @spec notify_active_lambdas(binary(), map()) :: [{:ok, any()} | {:error, any()}]
  def notify_active_lambdas(account_id, event) do
    account_id
    |> list_lambdas(%{status: "active"})
    |> Enum.filter(fn lambda -> should_handle_event?(lambda, event) end)
    |> Enum.map(fn lambda -> invoke(lambda, event) end)
  end

  @spec should_handle_event?(Lambda.t(), binary()) :: boolean()
  # Do not attempt to handle event if function name or code is missing
  def should_handle_event?(%Lambda{lambda_function_name: nil}, _event), do: false
  def should_handle_event?(%Lambda{code: nil}, _event), do: false
  # Handling these specific events by default for now
  def should_handle_event?(_lambda, %{"event" => "message:created"}), do: true
  def should_handle_event?(_lambda, %{"event" => "conversation:created"}), do: true
  def should_handle_event?(_lambda, _event), do: false

  @spec filter_where(map()) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    params
    |> Map.new(fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
    |> Enum.reduce(dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:creator_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.creator_id == ^value)

      {:status, value}, dynamic ->
        dynamic([r], ^dynamic and r.status == ^value)

      {:name, value}, dynamic ->
        dynamic([r], ^dynamic and r.name == ^value)

      {:q, ""}, dynamic ->
        dynamic

      {:q, query}, dynamic ->
        value = "%" <> query <> "%"

        dynamic(
          [r],
          ^dynamic and
            (ilike(r.name, ^value) or ilike(r.description, ^value))
        )

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
