defmodule ChatApiWeb.CSVHelpers do
  @moduledoc """
  Helper functions to deal with CSV data.

  This module is compliant with RFC-4180
  """

  @doc """
  Dumps an enumerable of maps or structs into a csv string
  using the given fields with respective order.

  ## Examples
      
      iex> CSVHelpers.dump_csv_rfc4180([%{name: "Papercups", awesome: true}], [:name, :awesome])
      "name,awesome\\r\\n\\"Papercups\\",\\"true\\""
  """
  @spec dump_csv_rfc4180([map() | struct()], list()) :: String.t()
  def dump_csv_rfc4180(rows, fields) when is_list(rows) and is_list(fields) do
    rows
    |> Enum.map(fn row ->
      fields
      |> Enum.map(fn field_name ->
        field_data =
          row
          # Fetch column or insert empty string if nil
          |> Map.get(field_name, "")
          # Ensure our data is string
          |> to_string()
          # Escape any double quotes in the string
          |> String.replace("\"", "\"\"")

        "\"#{field_data}\""
      end)
      |> Enum.join(",")
    end)
    |> List.insert_at(0, Enum.join(fields, ","))
    |> Enum.join("\r\n")
  end
end
