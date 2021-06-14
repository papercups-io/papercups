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

  @spec upload(Plug.Upload.t(), binary()) :: {:error, any} | {:ok, any()}
  def upload(file, identifier) do
    with {:ok, %{bucket_name: bucket_name}} <- Config.validate(),
         {:ok, file_binary} <- File.read(file.path) do
      bucket_name
      |> ExAws.S3.put_object(identifier, file_binary)
      |> ExAws.request!()
      |> case do
        %{status_code: 200} = result -> {:ok, result}
        result -> {:error, result}
      end
    else
      {:error, :invalid_aws_config, errors} -> {:error, :invalid_aws_config, errors}
      {:error, error} -> {:error, :file_error, error}
      error -> error
    end
  end

  def upload_binary(file_binary, identifier) do
    bucket = function_bucket_name()

    upload_binary(file_binary, identifier, bucket)
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

  def upload(file_path, unique_file_name, bucket_name) do
    with {:ok, file_binary} <- File.read(file_path) do
      bucket_name
      |> ExAws.S3.put_object(unique_file_name, file_binary)
      |> ExAws.request!()
      |> case do
        %{status_code: 200} = result -> {:ok, result}
        result -> {:error, result}
      end
    else
      {:error, :invalid_aws_config, errors} -> {:error, :invalid_aws_config, errors}
      {:error, error} -> {:error, :file_error, error}
      error -> error
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

  def list_functions() do
    ExAws.Lambda.list_functions() |> ExAws.request!()
  end

  # the lambda repo doesn't get maintained so it doesn't return a status code
  @spec get_function(binary) :: ExAws.Operation.JSON.t()
  def get_function(function_name) do
    function_name
    |> ExAws.Lambda.get_function()
    |> ExAws.request!()
  end

  @spec create_function(any(), any(), any(), any()) :: any()
  def create_function(file_path, function_name, handler, api_key \\ "") do
    uniq_function_name = generate_unique_filename(function_name)
    bucket = function_bucket_name()

    with {:ok, _} <- upload(file_path, uniq_function_name, bucket) do
      operation = %ExAws.Operation.JSON{
        http_method: :post,
        headers: [{"content-type", "application/json"}],
        path: "/2015-03-31/functions",
        data: %{
          "FunctionName" => uniq_function_name,
          "Handler" => handler,
          "Runtime" => "nodejs14.x",
          "Role" => "arn:aws:iam::#{aws_account_id()}:role/#{function_role()}",
          "Code" => %{
            "S3Bucket" => bucket,
            "S3Key" => uniq_function_name
          },
          "Environment" => %{
            "Variables" => %{
              "PAPERCUPS_API_KEY" => api_key
            }
          }
        },
        service: :lambda
      }

      ExAws.request!(operation)
    end
  end

  def code_upload(code, function_name, api_key \\ "") do
    {:ok, {_filename, bytes}} = :zip.create("test.zip", [{'index.js', code}], [:memory])
    bucket = function_bucket_name()
    _upload = upload_binary(bytes, function_name, bucket)

    operation = %ExAws.Operation.JSON{
      http_method: :post,
      path: "/2015-03-31/functions",
      headers: [{"content-type", "application/json"}],
      data: %{
        "FunctionName" => function_name,
        "Handler" => "index.handler",
        "Runtime" => "nodejs14.x",
        "Role" => "arn:aws:iam::#{aws_account_id()}:role/#{function_role()}",
        "Code" => %{
          "S3Bucket" => bucket,
          "S3Key" => function_name
        },
        "Environment" => %{
          "Variables" => %{
            "PAPERCUPS_API_KEY" => api_key
          }
        }
      },
      service: :lambda
    }

    ExAws.request!(operation)
  end

  def update_function(code, function_name) do
    {:ok, {_filename, bytes}} = :zip.create("test.zip", [{'index.js', code}], [:memory])
    bucket = function_bucket_name()
    _result = upload_binary(bytes, function_name, bucket)

    operation = %ExAws.Operation.JSON{
      http_method: :put,
      headers: [{"content-type", "application/json"}],
      path: "/2015-03-31/functions/#{function_name}/versions/HEAD/code",
      data: %{
        "Runtime" => "nodejs14.x",
        "Role" => "arn:aws:iam::#{aws_account_id()}:role/#{function_role()}",
        "S3Bucket" => bucket,
        "S3Key" => function_name
      },
      service: :lambda
    }

    ExAws.request!(operation)
  end

  def delete_function(function_name) do
    function_name
    |> ExAws.Lambda.delete_function()
    |> ExAws.request!()
  end

  def invoke_function(function_name, payload) do
    function_name
    |> ExAws.Lambda.invoke(payload, %{})
    |> ExAws.request!()
  end

  defp function_bucket_name(), do: Application.get_env(:chat_api, :function_bucket_name)
  defp function_role(), do: Application.get_env(:chat_api, :function_role)
  defp aws_account_id(), do: Application.get_env(:chat_api, :aws_account_id)
end
