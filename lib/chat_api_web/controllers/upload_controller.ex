defmodule ChatApiWeb.UploadController do
  use ChatApiWeb, :controller

  alias ChatApiWeb.FileView
  alias ChatApi.{Aws, Files}
  alias ChatApi.Files.FileUpload

  action_fallback ChatApiWeb.FallbackController

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(
        conn,
        %{
          "file" => %Plug.Upload{} = file,
          "account_id" => account_id
        } = params
      ) do
    # TODO: get `account_id` from request context rather than params
    filename = String.replace(file.filename, " ", "-")
    unique_filename = Aws.generate_unique_filename(filename)

    uploaded_file_params =
      params
      |> Map.delete("file")
      |> Map.merge(%{
        "filename" => filename,
        "unique_filename" => unique_filename,
        "file_url" => Aws.get_file_url(unique_filename),
        "content_type" => file.content_type,
        "account_id" => account_id
      })

    with {:ok, _result} = ChatApi.Aws.upload(file, unique_filename),
         {:ok, %FileUpload{} = file} <- Files.create_file(uploaded_file_params) do
      conn
      |> put_status(:created)
      |> put_view(FileView)
      |> render("show.json", file: file)
    end
  end
end
