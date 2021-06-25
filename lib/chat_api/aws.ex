defmodule ChatApi.Aws do
  @moduledoc """
  A module to handle interactions with AWS

  TODO: clean this up!
  """

  alias ChatApi.Aws.Config

  @type config() :: %{
          aws_key_id: binary(),
          aws_secret_key: binary(),
          bucket_name: binary(),
          function_bucket_name: binary(),
          region: binary()
        }

  # S3

  @spec upload(Plug.Upload.t(), binary()) :: {:error, any} | {:ok, any()}
  def upload(file, identifier) do
    with {:ok, %{bucket_name: bucket_name}} <- Config.validate(),
         {:ok, file_binary} <- File.read(file.path) do
      upload_binary(file_binary, identifier, bucket_name)
    else
      {:error, :invalid_aws_config, errors} -> {:error, :invalid_aws_config, errors}
      {:error, error} -> {:error, :file_error, error}
      error -> error
    end
  end

  @spec upload(binary(), binary(), binary()) :: {:error, any} | {:ok, any()}
  def upload(file_path, identifier, bucket_name) when is_binary(file_path) do
    case File.read(file_path) do
      {:ok, file_binary} -> upload_binary(file_binary, identifier, bucket_name)
      {:error, error} -> {:error, :file_error, error}
    end
  end

  def upload_binary(file_binary, identifier) do
    # TODO: consolidate Config methods with env variables below
    with {:ok, %{bucket_name: bucket_name}} <- Config.validate() do
      upload_binary(file_binary, identifier, bucket_name)
    end
  end

  def upload_binary(file_binary, identifier, bucket_name) do
    bucket_name
    |> ExAws.S3.put_object(identifier, file_binary)
    |> ExAws.request!()
    |> case do
      %{status_code: 200} = result -> {:ok, result}
      result -> {:error, result}
    end
  end

  @spec get_file_url(binary(), binary()) :: binary()
  def get_file_url(identifier, bucket) do
    "https://#{bucket}.s3.amazonaws.com/#{identifier}"
  end

  @spec get_file_url(binary()) :: binary() | nil
  def get_file_url(identifier) do
    case Config.validate() do
      {:ok, %{bucket_name: bucket}} -> get_file_url(identifier, bucket)
      _ -> nil
    end
  end

  @spec generate_unique_filename(Plug.Upload.t() | binary()) :: binary()
  def generate_unique_filename(%Plug.Upload{filename: filename}),
    do: generate_unique_filename(filename)

  def generate_unique_filename(filename) do
    uuid = UUID.uuid4(:hex)
    sanitized_filename = String.replace(filename, " ", "-")

    "#{uuid}-#{sanitized_filename}"
  end

  # Lambda

  @spec list_lambda_functions :: list()
  def list_lambda_functions() do
    ExAws.Lambda.list_functions() |> ExAws.request!()
  end

  # the lambda repo doesn't get maintained so it doesn't return a status code
  @spec get_lambda_function(binary()) :: any()
  def get_lambda_function(function_name) do
    function_name
    |> ExAws.Lambda.get_function()
    |> ExAws.request!()
  end

  @spec create_lambda_function(binary(), map()) :: any()
  def create_lambda_function(function_name, params \\ %{}) do
    %ExAws.Operation.JSON{
      http_method: :post,
      headers: [{"content-type", "application/json"}],
      path: "/2015-03-31/functions",
      data: %{
        "FunctionName" => function_name,
        "Handler" => Map.get(params, "handler", "index.handler"),
        "Runtime" => Map.get(params, "runtime", "nodejs14.x"),
        "Role" => "arn:aws:iam::#{aws_account_id()}:role/#{function_role()}",
        "Code" => %{
          "S3Bucket" => Map.get(params, "bucket", function_bucket_name()),
          "S3Key" => function_name
        },
        "Environment" => %{
          "Variables" => Map.get(params, "env", %{})
        }
      },
      service: :lambda
    }
    |> ExAws.request!()
  end

  @spec update_lambda_function_code(binary(), map()) :: any()
  def update_lambda_function_code(function_name, params \\ %{}) do
    # Reference: https://docs.aws.amazon.com/lambda/latest/dg/API_UpdateFunctionCode.html
    %ExAws.Operation.JSON{
      http_method: :put,
      headers: [{"content-type", "application/json"}],
      path: "/2015-03-31/functions/#{function_name}/code",
      data: %{
        "S3Bucket" => Map.get(params, "bucket", function_bucket_name()),
        "S3Key" => function_name
      },
      service: :lambda
    }
    |> ExAws.request!()
  end

  @spec update_lambda_function_config(binary(), map()) :: any()
  def update_lambda_function_config(function_name, params \\ %{}) do
    # Reference: https://docs.aws.amazon.com/lambda/latest/dg/API_UpdateFunctionConfiguration.html
    %ExAws.Operation.JSON{
      http_method: :put,
      headers: [{"content-type", "application/json"}],
      path: "/2015-03-31/functions/#{function_name}/configuration",
      data: %{
        "Runtime" => Map.get(params, "runtime", "nodejs14.x"),
        "Role" => "arn:aws:iam::#{aws_account_id()}:role/#{function_role()}",
        "Environment" => %{
          "Variables" => Map.get(params, "env", %{})
        }
      },
      service: :lambda
    }
    |> ExAws.request!()
  end

  @spec create_function_by_file(binary(), binary(), map()) :: any()
  def create_function_by_file(file_path, function_name, params \\ %{}) do
    bucket = function_bucket_name()

    with {:ok, _} <- upload(file_path, function_name, bucket) do
      create_lambda_function(
        function_name,
        Map.merge(params, %{
          "bucket" => bucket
        })
      )
    end
  end

  def update_function_by_file(file_path, function_name, params \\ %{}) do
    bucket = function_bucket_name()

    with {:ok, _} <- upload(file_path, function_name, bucket) do
      update_lambda_function_code(function_name, params)
    end
  end

  def create_function_by_code(code, function_name, params \\ %{}) do
    bucket = function_bucket_name()
    # TODO: does it matter what we name the zip file? (e.g. "test.zip"?)
    with {:ok, {_filename, bytes}} <- :zip.create("test.zip", [{'index.js', code}], [:memory]),
         {:ok, _} <- upload_binary(bytes, function_name, bucket) do
      create_lambda_function(
        function_name,
        Map.merge(params, %{
          "bucket" => bucket
        })
      )
    end
  end

  def update_function_by_code(code, function_name, params \\ %{}) do
    bucket = function_bucket_name()
    # TODO: does it matter what we name the zip file? (e.g. "test.zip"?)
    with {:ok, {_filename, bytes}} <- :zip.create("test.zip", [{'index.js', code}], [:memory]),
         {:ok, _} <- upload_binary(bytes, function_name, bucket) do
      # This update works because it syncs with the uploaded binary to S3 in the method above
      update_lambda_function_code(function_name, params)
    end
  end

  def update_function_configuration(function_name, params \\ %{}) do
    update_lambda_function_config(function_name, params)
  end

  @spec delete_lambda_function(binary()) :: any()
  def delete_lambda_function(function_name) do
    function_name
    |> ExAws.Lambda.delete_function()
    |> ExAws.request!()
  end

  @spec invoke_lambda_function(binary(), map()) :: any()
  def invoke_lambda_function(function_name, payload) do
    function_name
    |> ExAws.Lambda.invoke(payload, %{})
    |> ExAws.request!()
  end

  # TODO: maybe rename to `lambda` instead of just `function`?
  defp function_bucket_name(), do: Application.get_env(:chat_api, :function_bucket_name)
  defp function_role(), do: Application.get_env(:chat_api, :function_role)
  defp aws_account_id(), do: Application.get_env(:chat_api, :aws_account_id)
end
