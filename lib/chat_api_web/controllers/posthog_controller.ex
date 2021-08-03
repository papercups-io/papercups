defmodule ChatApiWeb.PosthogController do
  use ChatApiWeb, :controller

  alias Plug.Conn

  @spec events(Conn.t(), map()) :: Conn.t()
  def events(conn, _params) do
    json(conn, %{
      data: []
    })
  end

  @spec persons(Conn.t(), map()) :: Conn.t()
  def persons(conn, _params) do
    json(conn, %{
      data: []
    })
  end
end
