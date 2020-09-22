defmodule ChatApiWeb.SessionController do
  use ChatApiWeb, :controller

  alias ChatApiWeb.APIAuthPlug
  alias Plug.Conn

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.authenticate_user(user_params)
    |> case do
      {:ok, conn} ->
        conn
        |> ChatApiWeb.EnsureUserEnabledPlug.call()
        |> case do
          %{halted: true} = conn ->
            conn

          conn ->
            json(conn, %{
              data: %{
                user_id: conn.assigns.current_user.id,
                email: conn.assigns.current_user.email,
                account_id: conn.assigns.current_user.account_id,
                token: conn.private[:api_auth_token],
                renew_token: conn.private[:api_renew_token]
              }
            })
        end

      {:error, conn} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid email or password"}})
    end
  end

  @spec renew(Conn.t(), map()) :: Conn.t()
  def renew(conn, _params) do
    config = Pow.Plug.fetch_config(conn)

    conn
    |> APIAuthPlug.renew(config)
    |> case do
      {conn, nil} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid token"}})

      {conn, user} ->
        conn
        |> ChatApiWeb.EnsureUserEnabledPlug.call(user)
        |> case do
          %{halted: true} = conn ->
            conn

          conn ->
            json(conn, %{
              data: %{
                user_id: user.id,
                email: user.email,
                account_id: user.account_id,
                token: conn.private[:api_auth_token],
                renew_token: conn.private[:api_renew_token]
              }
            })
        end
    end
  end

  @spec delete(Conn.t(), map()) :: Conn.t()
  def delete(conn, _params) do
    conn
    |> Pow.Plug.delete()
    |> json(%{data: %{}})
  end

  @spec me(Conn.t(), map()) :: Conn.t()
  def me(conn, _params) do
    case conn.assigns.current_user do
      %{id: id, email: email, account_id: account_id, role: role} ->
        json(conn, %{
          data: %{
            id: id,
            email: email,
            account_id: account_id,
            role: role
          }
        })

      nil ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid token"}})
    end
  end
end
