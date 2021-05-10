defmodule ChatApiWeb.UploadController do
  use ChatApiWeb, :controller

  alias ChatApiWeb.FileView
  alias ChatApi.{Aws, Files}
  alias ChatApi.Files.FileUpload

  action_fallback(ChatApiWeb.FallbackController)

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

    with {:ok, _result} <- Aws.upload(file, unique_filename),
         {:ok, %FileUpload{} = file} <- Files.create_file(uploaded_file_params) do
      conn
      |> put_status(:created)
      |> put_view(FileView)
      |> render("show.json", file: file)
    else
      {:error, :invalid_aws_config, errors} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Missing AWS keys: #{inspect(errors)}"}})

      {:error, :file_error, error} ->
        conn
        |> put_status(422)
        |> json(%{error: %{status: 422, message: "Invalid or malformed file: #{inspect(error)}"}})

      error ->
        error
    end
  end
end
