defmodule ChatApi.Google.Sheets do
  @spec get_spreadsheet_info(binary(), binary()) :: {:error, any()} | {:ok, OAuth2.Response.t()}
  def get_spreadsheet_info(refresh_token, id) do
    with {:ok, client} <- ChatApi.Google.Auth.get_access_token(refresh_token: refresh_token) do
      scope = "https://sheets.googleapis.com/v4/spreadsheets/#{id}"

      OAuth2.Client.get(client, scope)
    end
  end

  @spec get_spreadsheet_values(binary(), binary()) :: {:error, any()} | {:ok, OAuth2.Response.t()}
  def get_spreadsheet_values(refresh_token, id) do
    with {:ok, client} <- ChatApi.Google.Auth.get_access_token(refresh_token: refresh_token),
         {:ok, %{body: %{"sheets" => _} = result}} <- get_spreadsheet_info(refresh_token, id),
         {:ok, [default_sheet_name | _]} <- extract_sheet_names(result) do
      range = "#{default_sheet_name}!A:Z"
      scope = "https://sheets.googleapis.com/v4/spreadsheets/#{id}/values/#{range}"

      OAuth2.Client.get(client, scope)
    end
  end

  @spec get_spreadsheet_values(binary(), binary(), binary()) ::
          {:error, any()} | {:ok, OAuth2.Response.t()}
  def get_spreadsheet_values(refresh_token, id, range) do
    with {:ok, client} <- ChatApi.Google.Auth.get_access_token(refresh_token: refresh_token) do
      scope = "https://sheets.googleapis.com/v4/spreadsheets/#{id}/values/#{range}"

      OAuth2.Client.get(client, scope)
    end
  end

  @spec get_spreadsheet_by_id(binary(), binary(), binary()) ::
          {:error, any()} | {:ok, OAuth2.Response.t()}
  def get_spreadsheet_by_id(refresh_token, id, range \\ "Sheet1!A:Z") do
    with {:ok, client} <- ChatApi.Google.Auth.get_access_token(refresh_token: refresh_token) do
      scope = "https://sheets.googleapis.com/v4/spreadsheets/#{id}/values/#{range}"

      OAuth2.Client.get(client, scope)
    end
  end

  @spec get_spreadsheet_by_id!(binary(), binary(), binary()) :: OAuth2.Response.t()
  def get_spreadsheet_by_id!(refresh_token, id, range \\ "Sheet1!A:Z") do
    case get_spreadsheet_by_id(refresh_token, id, range) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec append_to_spreadsheet(binary(), binary(), keyword(), binary()) ::
          {:error, any()} | {:ok, OAuth2.Response.t()}
  def append_to_spreadsheet(refresh_token, id, data \\ [], range \\ "Sheet1!A:Z") do
    with {:ok, client} <- ChatApi.Google.Auth.get_access_token(refresh_token: refresh_token) do
      qs = URI.encode_query(%{valueInputOption: "USER_ENTERED", includeValuesInResponse: true})
      scope = "https://sheets.googleapis.com/v4/spreadsheets/#{id}/values/#{range}:append?#{qs}"

      payload = %{
        "majorDimension" => "ROWS",
        "range" => range,
        "values" =>
          if Enum.all?(data, &is_list/1) do
            data
          else
            # If we're only inserting one row, make sure it's formatted properly
            [data]
          end
      }

      OAuth2.Client.post(client, scope, payload)
    end
  end

  @spec append_to_spreadsheet!(binary(), binary(), keyword(), binary()) :: OAuth2.Response.t()
  def append_to_spreadsheet!(refresh_token, id, data \\ [], range \\ "Sheet1!A:Z") do
    case append_to_spreadsheet(refresh_token, id, data, range) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  def extract_sheet_names(%{"sheets" => sheets}) when is_list(sheets) do
    {:ok,
     Enum.map(sheets, fn sheet ->
       get_in(sheet, ["properties", "title"])
     end)}
  end

  def extract_sheet_names(_), do: {:error, "Unable to find sheets for spreadsheet!"}

  def format_as_json(%{"values" => values}) when is_list(values) do
    [headers | rows] = Enum.reject(values, &Enum.empty?/1)

    keys =
      Enum.map(headers, fn header ->
        header |> String.split(" ") |> Enum.join("_") |> String.downcase()
      end)

    Enum.map(rows, fn items ->
      items
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {value, index}, acc ->
        case Enum.at(keys, index) do
          nil -> acc
          key -> Map.merge(acc, %{key => value})
        end
      end)
    end)
  end

  def format_as_json(_response), do: []
end
