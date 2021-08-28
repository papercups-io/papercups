defmodule ChatApiWeb.GoogleSheetsController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Google

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, params) do
    with {:ok, google_sheet_id} <- extract_google_sheet_id(params),
         %{account_id: account_id} <- conn.assigns.current_user,
         %{refresh_token: refresh_token} <-
           Google.get_google_sheets_authorization(account_id) do
      response =
        case params do
          %{"range" => range} ->
            Google.Sheets.get_spreadsheet_values(refresh_token, google_sheet_id, range)

          %{"sheet" => sheet} ->
            Google.Sheets.get_spreadsheet_values(refresh_token, google_sheet_id, "#{sheet}!A:Z")

          _ ->
            Google.Sheets.get_spreadsheet_values(refresh_token, google_sheet_id)
        end

      case response do
        {:ok, %{body: result}} ->
          json(conn, %{ok: true, data: Google.Sheets.format_as_json(result)})

        {:error, %{body: %{"error" => %{"code" => code} = error}}} ->
          conn
          |> put_status(code)
          |> json(%{error: error})

        {:error, error} ->
          conn
          |> put_status(500)
          |> json(%{error: "Unexpected error: #{inspect(error)}"})
      end
    end
  end

  def extract_google_sheet_id(%{"id" => google_sheet_id}),
    do: {:ok, google_sheet_id}

  def extract_google_sheet_id(%{"url" => google_sheet_url}) do
    %URI{path: path} = URI.parse(google_sheet_url)

    case String.split(path, "/", trim: true) do
      ["spreadsheets", "d", google_sheet_id | _] -> {:ok, google_sheet_id}
      _ -> {:error, "Invalid Google Sheets URL: #{google_sheet_url}"}
    end
  end
end
