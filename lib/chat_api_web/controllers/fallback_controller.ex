defmodule ChatApiWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use ChatApiWeb, :controller

  alias Ecto.Changeset
  alias ChatApiWeb.ErrorHelpers

  # This clause is an example of how to handle resources that cannot be found.
  @spec call(Plug.Conn.t(), tuple()) :: Plug.Conn.t()
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(404)
    |> json(%{
      error: %{
        status: 404,
        message: "Not found"
      }
    })
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

    conn
    |> put_status(422)
    |> json(%{
      error: %{
        status: 422,
        message: "Unprocessable Entity",
        errors: errors
      }
    })
  end
end
