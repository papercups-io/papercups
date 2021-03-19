defmodule ChatApiWeb.CompanyController do
  use ChatApiWeb, :controller

  alias ChatApi.Companies
  alias ChatApi.Companies.Company

  action_fallback ChatApiWeb.FallbackController

  plug :authorize when action in [:show, :update, :delete]

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         company = %{account_id: ^account_id} <- Companies.get_company!(id) do
      assign(conn, :current_company, company)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      companies = Companies.list_companies(account_id)
      render(conn, "index.json", companies: companies)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"company" => company_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         {:ok, %Company{} = company} <-
           company_params
           |> Map.merge(%{"account_id" => account_id})
           |> Companies.create_company() do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.company_path(conn, :show, company))
      |> render("show.json", company: company)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => _id}) do
    render(conn, "show.json", company: conn.assigns.current_company)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => _id, "company" => company_params}) do
    with {:ok, %Company{} = company} <-
           Companies.update_company(conn.assigns.current_company, company_params) do
      render(conn, "show.json", company: company)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => _id}) do
    with {:ok, %Company{}} <- Companies.delete_company(conn.assigns.current_company) do
      send_resp(conn, :no_content, "")
    end
  end
end
