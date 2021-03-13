defmodule ChatApiWeb.CannedResponseController do
  use ChatApiWeb, :controller

  alias ChatApi.CannedResponses
  alias ChatApi.CannedResponses.CannedResponse

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      canned_responses = CannedResponses.list_canned_responses_by_account(account_id)
      render(conn, "index.json", canned_responses: canned_responses)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(
        conn,
        %{
          "content" => content,
          "name" => name
        }
      ) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         {:ok, %CannedResponse{} = canned_response} <-
           CannedResponses.create_canned_response(%{
             content: content,
             name: name,
             account_id: account_id
           }) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.canned_response_path(conn, :show, canned_response))
      |> render("show.json", canned_response: canned_response)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    canned_response = CannedResponses.get_canned_response!(id)

    with :ok <- is_authorized?(conn.assigns.current_user, canned_response) do
      render(conn, "show.json", canned_response: canned_response)
    end
  end

  def update(conn, %{"id" => id, "content" => content, "name" => name}) do
    canned_response = CannedResponses.get_canned_response!(id)

    with :ok <- is_authorized?(conn.assigns.current_user, canned_response),
         {:ok, %CannedResponse{} = canned_response} <-
           CannedResponses.update_canned_response(canned_response, %{
             name: name,
             content: content
           }) do
      render(conn, "show.json", canned_response: canned_response)
    end
  end

  def delete(conn, %{"id" => id}) do
    canned_response = CannedResponses.get_canned_response!(id)

    with :ok <- is_authorized?(conn.assigns.current_user, canned_response),
         {:ok, %CannedResponse{}} <- CannedResponses.delete_canned_response(canned_response) do
      send_resp(conn, :no_content, "")
    end
  end

  defp is_authorized?(user, canned_response) do
    cond do
      user.role == "admin" ->
        :ok

      user.account_id == canned_response.account_id ->
        :ok

      true ->
        {:error, :forbidden}
    end
  end
end
