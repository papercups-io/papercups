defmodule ChatApi.Aws.Config do
  @moduledoc """
  A module to handle AWS config
  """

  @type t() :: %{
          aws_key_id: binary(),
          aws_secret_key: binary(),
          bucket_name: binary(),
          region: binary()
        }

  @spec validate(t()) :: {:error, [any()]} | {:ok, t()}
  def validate(config) do
    missing_env_keys =
      Enum.filter(config, fn {_key, value} ->
        case value do
          "" -> true
          nil -> true
          _ -> false
        end
      end)

    case missing_env_keys do
      [] -> {:ok, config}
      missing -> {:error, missing}
    end
  end

  @spec validate :: {:error, [any()]} | {:ok, t()}
  def validate() do
    get() |> validate()
  end

  @spec get :: t()
  def get() do
    %{
      aws_key_id: System.get_env("AWS_ACCESS_KEY_ID", ""),
      aws_secret_key: System.get_env("AWS_SECRET_ACCESS_KEY", ""),
      bucket_name: System.get_env("BUCKET_NAME", ""),
      region: System.get_env("AWS_REGION", "")
    }
  end
end
