defmodule ChatApiWeb.LambdaController do
  use ChatApiWeb, :controller

  alias ChatApi.Lambdas
  alias ChatApi.Lambdas.Lambda

  action_fallback ChatApiWeb.FallbackController

  plug(:authorize when action in [:show, :update, :delete])

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         %{account_id: ^account_id} = lambda <- Lambdas.get_lambda!(id) do
      assign(conn, :current_lambda, lambda)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{current_user: %{account_id: account_id}}} = conn, params) do
    lambdas = Lambdas.list_lambdas(account_id, params)

    render(conn, "index.json", lambdas: lambdas)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(%{assigns: %{current_user: %{account_id: account_id, id: creator_id}}} = conn, %{
        "lambda" => lambda_params
      }) do
    with {:ok, %Lambda{} = lambda} <-
           lambda_params
           |> Map.merge(%{"creator_id" => creator_id, "account_id" => account_id})
           |> Lambdas.create_lambda() do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.lambda_path(conn, :show, lambda))
      |> render("show.json", lambda: lambda)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _params) do
    render(conn, "show.json", lambda: conn.assigns.current_lambda)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"lambda" => lambda_params}) do
    with {:ok, %Lambda{} = lambda} <-
           Lambdas.update_lambda(conn.assigns.current_lambda, lambda_params) do
      render(conn, "show.json", lambda: lambda)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    with {:ok, %Lambda{}} <- Lambdas.delete_lambda(conn.assigns.current_lambda) do
      send_resp(conn, :no_content, "")
    end
  end
end
