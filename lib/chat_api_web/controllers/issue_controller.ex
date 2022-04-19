defmodule ChatApiWeb.IssueController do
  use ChatApiWeb, :controller

  alias ChatApi.Issues
  alias ChatApi.Issues.Issue

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete])

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         issue = %{account_id: ^account_id} <- Issues.get_issue!(id) do
      assign(conn, :current_issue, issue)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{current_user: %{account_id: account_id}}} = conn, params) do
    issues = Issues.list_issues(account_id, params)

    render(conn, "index.json", issues: issues)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(%{assigns: %{current_user: %{account_id: account_id, id: creator_id}}} = conn, %{
        "issue" => issue_params
      }) do
    with {:ok, %Issue{} = issue} <-
           issue_params
           |> Map.merge(%{"creator_id" => creator_id, "account_id" => account_id})
           |> Issues.create_issue() do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.issue_path(conn, :show, issue))
      |> render("show.json", issue: issue)
    end
  end

  def show(conn, _params) do
    render(conn, "show.json", issue: conn.assigns.current_issue)
  end

  def update(conn, %{"issue" => issue_params}) do
    with {:ok, %Issue{} = issue} <- Issues.update_issue(conn.assigns.current_issue, issue_params) do
      render(conn, "show.json", issue: issue)
    end
  end

  def delete(conn, _params) do
    with {:ok, %Issue{}} <- Issues.delete_issue(conn.assigns.current_issue) do
      send_resp(conn, :no_content, "")
    end
  end
end
