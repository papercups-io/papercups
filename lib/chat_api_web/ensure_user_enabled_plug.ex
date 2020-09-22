defmodule ChatApiWeb.EnsureUserEnabledPlug do
  @moduledoc """
  This plug ensures that a user isn't disabled or archived.

  ## Example

      plug ChatApiWeb.EnsureUserEnabledPlug
  """
  import Plug.Conn, only: [halt: 1, put_status: 2]

  alias Phoenix.Controller
  alias Plug.Conn
  alias Pow.Plug

  @doc false
  @spec init(any()) :: any()
  def init(opts), do: opts

  @doc false
  @spec call(Conn.t()) :: Conn.t()
  def call(conn) do
    conn
    |> Plug.current_user()
    |> disabled?()
    |> maybe_halt(conn)
  end

  @doc false
  @spec call(Conn.t(), any()) :: Conn.t()
  def call(conn, user) do
    user
    |> disabled?()
    |> maybe_halt(conn)
  end

  defp disabled?(%{disabled_at: disabled_at, archived_at: archived_at})
       when not is_nil(disabled_at)
       when not is_nil(archived_at),
       do: true

  defp disabled?(_user), do: false

  defp maybe_halt(true, conn) do
    conn
    |> Plug.delete()
    |> put_status(401)
    |> Controller.json(%{
      error: %{
        status: 401,
        message:
          "Your account is disabled. Please contact your team admin to enable your account."
      }
    })
    |> halt()
  end

  defp maybe_halt(_any, conn), do: conn
end
