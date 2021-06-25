defmodule ChatApiWeb.LambdaController do
  use ChatApiWeb, :controller

  alias ChatApi.Lambdas
  alias ChatApi.Lambdas.Lambda

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete, :deploy, :invoke])

  @spec authorize(Plug.Conn.t(), any()) :: any()
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

  @spec deploy(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def deploy(conn, %{"file" => file} = params) do
    with %{current_lambda: lambda, current_user: %{id: user_id, account_id: account_id}} <-
           conn.assigns,
         # NB: for now we just get the most recent API key rather than passing it through as a param
         %ChatApi.ApiKeys.PersonalApiKey{value: api_key} <-
           ChatApi.ApiKeys.list_personal_api_keys(user_id, account_id) |> List.last(),
         opts <-
           params
           |> Map.delete("file")
           |> Map.merge(%{"env" => %{"PAPERCUPS_API_KEY" => api_key}}),
         {:ok, %Lambda{} = lambda} <- Lambdas.deploy_file(lambda, file, opts),
         updates <- Map.take(params, ["name", "description", "code"]),
         {:ok, %Lambda{} = lambda} <- Lambdas.update_lambda(lambda, updates) do
      render(conn, "show.json", lambda: lambda)
    end
  end

  def deploy(conn, params) do
    with {:ok, %Lambda{} = lambda} <-
           Lambdas.deploy(conn.assigns.current_lambda, params) do
      render(conn, "show.json", lambda: lambda)
    end
  end

  @spec invoke(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def invoke(conn, params) do
    case conn.assigns.current_lambda do
      %Lambda{lambda_function_name: lambda_function_name}
      when is_binary(lambda_function_name) ->
        json(conn, %{data: ChatApi.Aws.invoke_lambda_function(lambda_function_name, params)})

      %Lambda{lambda_function_name: _} ->
        json(conn, %{data: nil})
    end
  end

  def deps(conn, _params) do
    send_file(conn, 200, "./priv/static/deps.zip")
  end
end
