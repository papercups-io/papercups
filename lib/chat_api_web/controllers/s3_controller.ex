defmodule ChatApiWeb.S3Controller do
  use ChatApiWeb, :controller

  action_fallback ChatApiWeb.FallbackController

  def presigned_upload_url(conn, %{
        "filename" => filename
      }) do
    file_uuid = UUID.uuid4(:hex)
    filename = String.replace(filename, " ", "-")

    unique_filename = "#{file_uuid}-#{filename}"

    bucket_name = System.get_env("BUCKET_NAME")

    if bucket_name == nil do
      raise "s3 bucket is not specified"
    end

    config = ExAws.Config.new(:s3)

    with {:ok, signed_url} <- ExAws.S3.presigned_url(config, :put, bucket_name, unique_filename) do
      conn
      |> put_status(:created)
      |> json(%{signed_url: signed_url})
    end
  end
end
