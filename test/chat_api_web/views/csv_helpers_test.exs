defmodule ChatApiWeb.CSVHelpersTest do
  use ExUnit.Case
  alias ChatApiWeb.CSVHelpers
  doctest CSVHelpers

  test "Column with newline encodes correctly" do
    data =
      CSVHelpers.dump_csv_rfc4180(
        [
          %{column1: "This is \n an \r\nanomoly", column2: "This is not!"},
          %{column1: "This is normal", column2: "Also this"}
        ],
        [:column1, :column2]
      )

    assert data ==
             "column1,column2\r\n" <>
               "\"This is \n" <>
               " an \r\n" <>
               "anomoly\",\"This is not!\"\r\n" <>
               "\"This is normal\",\"Also this\""
  end

  test "Columns with double-quotes encode correctly" do
    data =
      CSVHelpers.dump_csv_rfc4180(
        [
          %{column1: "This is \" an \"anomoly", column2: "This is not!"},
          %{column1: "This is normal", column2: "Also this"}
        ],
        [:column1, :column2]
      )

    assert data ==
             "column1,column2\r\n" <>
               "\"This is \"\" an \"\"anomoly\",\"This is not!\"\r\n" <>
               "\"This is normal\",\"Also this\""
  end

  test "nil columns should encode as empty string" do
    data = CSVHelpers.dump_csv_rfc4180([%{data: nil, name: "papercups"}], [:name, :data])

    assert data ==
             "name,data\r\n" <>
               "\"papercups\",\"\""
  end

  test "unreferenced columns should not get encoded" do
    data =
      CSVHelpers.dump_csv_rfc4180([%{public: "This is public", private: "This is PRIVATE"}], [
        :public
      ])

    assert data == "public\r\n\"This is public\""
  end
end
