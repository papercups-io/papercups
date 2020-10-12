defmodule ChatApiWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use ChatApiWeb, :controller

  # This clause is an example of how to handle resources that cannot be found.
  @spec call(Plug.Conn.t(), tuple()) :: Plug.Conn.t()
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ChatApiWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, %Ecto.Changeset{}}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ChatApiWeb.ErrorView)
    |> render(:"422")
  end
end
