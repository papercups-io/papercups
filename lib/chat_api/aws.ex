defmodule ChatApi.Aws do
  @moduledoc """
  A module to handle interactions with AWS
  """

  @config %{
    aws_key_id: System.get_env("AWS_ACCESS_KEY_ID", ""),
    aws_secret_key: System.get_env("AWS_SECRET_ACCESS_KEY", ""),
    bucket_name: System.get_env("BUCKET_NAME", ""),
    region: System.get_env("AWS_REGION", "")
  }

  @type config() :: %{
          aws_key_id: binary(),
          aws_secret_key: binary(),
          bucket_name: binary(),
          region: binary()
        }

  @spec upload(Plug.Upload.t(), binary()) :: {:error, any} | {:ok, any()}
  def upload(file, identifier) do
    with {:ok, %{bucket_name: bucket_name}} <- validate_config(),
         {:ok, file_binary} = File.read(file.path) do
      bucket_name
      |> ExAws.S3.put_object(identifier, file_binary)
      |> ExAws.request!()
      |> case do
        %{status_code: 200} = result -> {:ok, result}
        result -> {:error, result}
      end
    else
      error -> {:error, error}
    end
  end

  @spec get_file_url(binary(), binary()) :: binary()
  def get_file_url(identifier, bucket) do
    "https://#{bucket}.s3.amazonaws.com/#{bucket}/#{identifier}"
  end

  @spec get_file_url(binary()) :: binary()
  def get_file_url(identifier) do
    get_file_url(identifier, @config.bucket_name)
  end

  @spec generate_unique_filename(Plug.Upload.t() | binary()) :: binary()
  def generate_unique_filename(%Plug.Upload{filename: filename}),
    do: generate_unique_filename(filename)

  def generate_unique_filename(filename) do
    uuid = UUID.uuid4(:hex)
    sanitized_filename = String.replace(filename, " ", "-")

    "#{uuid}-#{sanitized_filename}"
  end

  @spec validate_config :: {:error, [any()]} | {:ok, config()}
  def validate_config() do
    missing_env_keys =
      Enum.filter(@config, fn {_key, value} ->
        case value do
          "" -> true
          nil -> true
          _ -> false
        end
      end)

    case missing_env_keys do
      [] -> {:ok, @config}
      missing -> {:error, missing}
    end
  end
end
