defmodule ChatApiWeb.CompanyController do
  use ChatApiWeb, :controller

  alias ChatApi.Companies
  alias ChatApi.Companies.Company

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      companies = Companies.list_companies(account_id)
      render(conn, "index.json", companies: companies)
    end
  end

  def create(conn, %{"company" => company_params}) do
    with {:ok, %Company{} = company} <- Companies.create_company(company_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.company_path(conn, :show, company))
      |> render("show.json", company: company)
    end
  end

  def show(conn, %{"id" => id}) do
    company = Companies.get_company!(id)
    render(conn, "show.json", company: company)
  end

  def update(conn, %{"id" => id, "company" => company_params}) do
    company = Companies.get_company!(id)

    with {:ok, %Company{} = company} <- Companies.update_company(company, company_params) do
      render(conn, "show.json", company: company)
    end
  end

  def delete(conn, %{"id" => id}) do
    company = Companies.get_company!(id)

    with {:ok, %Company{}} <- Companies.delete_company(company) do
      send_resp(conn, :no_content, "")
    end
  end
end
