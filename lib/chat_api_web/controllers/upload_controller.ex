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

  @spec csv(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def csv(conn, %{"csv" => csv}) do
    with {:ok, data} <- csv_to_json(csv) do
      json(conn, %{
        _csv: csv,
        data: data
      })
    else
      error ->
        conn
        |> put_status(422)
        |> json(%{
          error: %{status: 422, message: "Invalid or malformed CSV: #{inspect(error)}"}
        })
    end
  end

  def csv(conn, %{"file" => %Plug.Upload{} = file}) do
    with {:ok, csv} <- File.read(file.path),
         list <- File.stream!(file.path) |> CSV.decode() |> Enum.to_list(),
         {:ok, data} <- csv_to_json(list) do
      json(conn, %{
        _csv: csv,
        data: data
      })
    else
      error ->
        conn
        |> put_status(422)
        |> json(%{
          error: %{status: 422, message: "Invalid or malformed CSV: #{inspect(error)}"}
        })
    end
  end

  @spec csv_to_json(binary() | list()) :: {:ok, [map()]} | {:error, any()}
  def csv_to_json(csv) when is_binary(csv) do
    if is_valid_csv?(csv) do
      csv |> String.split("\n") |> CSV.decode() |> Enum.to_list() |> csv_to_json()
    else
      {:error, :invalid_csv}
    end
  end

  def csv_to_json([header | rows]) do
    with {:ok, [_ | _] = columns} <- header do
      # TODO: just use Enum.reduce instead?
      {:ok,
       rows
       |> Enum.filter(fn
         {:ok, _} -> true
         {:error, _} -> false
       end)
       |> Enum.map(fn {:ok, row} ->
         columns |> Enum.zip(row) |> Map.new()
       end)}
    end
  end

  defp is_valid_csv?(str) when is_binary(str) do
    str
    |> String.split("\n")
    |> Enum.all?(fn row ->
      l = row |> String.split(",") |> length()

      l > 0
    end)
  end

  defp is_valid_csv?(_), do: false
end
