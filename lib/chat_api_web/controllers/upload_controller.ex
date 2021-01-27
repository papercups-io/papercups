defmodule ChatApiWeb.UploadController do
  use ChatApiWeb, :controller

  alias ChatApi.Uploads
  alias ChatApi.Uploads.Upload

  action_fallback ChatApiWeb.FallbackController

  def create(conn, %{"file" => file, "account_id" => account_id, "user_id" => user_id}) do
    file_uuid = UUID.uuid4(:hex)
    filename = String.replace(file.filename, " ", "-")

    unique_filename = "#{file_uuid}-#{filename}"
    {:ok, file_binary} = File.read(file.path)
    bucket_name = System.get_env("BUCKET_NAME")

    if bucket_name == nil do
      raise "s3 bucket is not specified"
    end

    upload_result =
      ExAws.S3.put_object(bucket_name, unique_filename, file_binary)
      |> ExAws.request!()

    if upload_result.status_code != 200 do
      raise "s3 upload failed"
    end

    updated_params = %{
      "filename" => "#{filename}",
      "unique_filename" => "#{unique_filename}",
      "file_url" => "https://#{bucket_name}.s3.amazonaws.com/#{bucket_name}/#{unique_filename}",
      "content_type" => file.content_type,
      "account_id" => account_id,
      "user_id" => user_id
    }

    with {:ok, %Upload{} = upload} <- Uploads.create_upload(updated_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.upload_path(conn, :show, upload))
      |> render("show.json", upload: upload)
    end
  end
end
