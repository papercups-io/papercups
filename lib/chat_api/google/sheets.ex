defmodule ChatApi.Google.Sheets do
  # TODO: refactor the same way Gmail is handled

  def get_spreadsheet_by_id!(refresh_token, id, range \\ "Sheet1!A:Z") do
    scope = "https://sheets.googleapis.com/v4/spreadsheets/#{id}/values/#{range}"
    client = ChatApi.Google.Auth.get_access_token!(refresh_token: refresh_token)
    %{body: result} = OAuth2.Client.get!(client, scope)

    result
  end

  def append_to_spreadsheet!(refresh_token, id, data \\ [], range \\ "Sheet1!A:Z") do
    qs = URI.encode_query(%{valueInputOption: "USER_ENTERED", includeValuesInResponse: true})
    scope = "https://sheets.googleapis.com/v4/spreadsheets/#{id}/values/#{range}:append?#{qs}"
    client = ChatApi.Google.Auth.get_access_token!(refresh_token: refresh_token)

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

    %{body: result} = OAuth2.Client.post!(client, scope, payload)

    result
  end

  def format_as_json(%{"values" => values}) when is_list(values) do
    [headers | rows] = values

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
