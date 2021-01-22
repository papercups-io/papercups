defmodule ChatApiWeb.UploadController do
  use ChatApiWeb, :controller

  alias ChatApi.Uploads
  alias ChatApi.Uploads.Upload

  action_fallback ChatApiWeb.FallbackController

  def create(conn, %{
        "filename" => filename,
        "content_type" => content_type
      }) do
    file_uuid = UUID.uuid4(:hex)
    filename = String.replace(filename, " ", "-")

    unique_filename = "#{file_uuid}-#{filename}"

    bucket_name = System.get_env("BUCKET_NAME")

    if bucket_name == nil do
      raise "s3 bucket is not specified"
    end

    updated_params = %{
      "filename" => "#{unique_filename}",
      "file_url" => "https://#{bucket_name}.s3.amazonaws.com/#{bucket_name}/#{unique_filename}",
      "content_type" => content_type
    }

    with {:ok, %Upload{} = upload} <- Uploads.create_upload(updated_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.upload_path(conn, :show, upload))
      |> render("show.json", upload: upload)
    end
  end

  def show(conn, %{"id" => id}) do
    upload = Uploads.get_upload!(id)
    render(conn, "show.json", upload: upload)
  end

  def delete(conn, %{"id" => id}) do
    upload = Uploads.get_upload!(id)

    bucket_name = System.get_env("BUCKET_NAME")

    if bucket_name == nil do
      raise "s3 bucket is not specified"
    end

    result = ExAws.S3.delete_object(bucket_name, upload.filename) |> ExAws.request!()

    with {:ok, %Upload{}} <- Uploads.delete_upload(upload) do
      send_resp(conn, :no_content, "")
    end
  end
end
