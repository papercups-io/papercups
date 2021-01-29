defmodule ChatApi.Aws do
  @moduledoc """
  A module to handle interactions with AWS
  """

  alias ChatApi.Aws.Config

  @type config() :: %{
          aws_key_id: binary(),
          aws_secret_key: binary(),
          bucket_name: binary(),
          region: binary()
        }

  @spec upload(Plug.Upload.t(), binary()) :: {:error, any} | {:ok, any()}
  def upload(file, identifier) do
    with {:ok, %{bucket_name: bucket_name}} <- Config.validate(),
         {:ok, file_binary} = File.read(file.path) do
      bucket_name
      |> ExAws.S3.put_object(identifier, file_binary)
      |> ExAws.request!()
      |> case do
        %{status_code: 200} = result -> {:ok, result}
        result -> {:error, result}
      end
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  @spec get_file_url(binary(), binary()) :: binary()
  def get_file_url(identifier, bucket) do
    "https://#{bucket}.s3.amazonaws.com/#{bucket}/#{identifier}"
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
end
