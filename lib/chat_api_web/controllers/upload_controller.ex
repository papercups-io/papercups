defmodule ChatApiWeb.UploadController do
  use ChatApiWeb, :controller

  alias ChatApi.{Aws, Uploads}
  alias ChatApi.Uploads.Upload

  action_fallback ChatApiWeb.FallbackController

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{
        "file" => %Plug.Upload{} = file,
        "account_id" => account_id,
        "user_id" => user_id
      }) do
    filename = String.replace(file.filename, " ", "-")
    unique_filename = Aws.generate_unique_filename(filename)

    uploaded_file_params = %{
      "filename" => filename,
      "unique_filename" => unique_filename,
      "file_url" => Aws.get_file_url(unique_filename),
      "content_type" => file.content_type,
      "account_id" => account_id,
      "user_id" => user_id
    }

    with {:ok, _result} = ChatApi.Aws.upload(file, unique_filename),
         {:ok, %Upload{} = upload} <- Uploads.create_upload(uploaded_file_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.upload_path(conn, :show, upload))
      |> render("show.json", upload: upload)
    end
  end
end
