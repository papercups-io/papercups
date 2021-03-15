defmodule ChatApiWeb.CannedResponseController do
  use ChatApiWeb, :controller

  alias ChatApi.CannedResponses
  alias ChatApi.CannedResponses.CannedResponse

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      canned_responses = CannedResponses.list_canned_responses(account_id)
      render(conn, "index.json", canned_responses: canned_responses)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"canned_response" => canned_response_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         {:ok, %CannedResponse{} = canned_response} <-
           canned_response_params
           |> Map.merge(%{"account_id" => account_id})
           |> CannedResponses.create_canned_response() do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.canned_response_path(conn, :show, canned_response))
      |> render("show.json", canned_response: canned_response)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    canned_response = CannedResponses.get_canned_response!(id)
    render(conn, "show.json", canned_response: canned_response)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id, "canned_response" => canned_response_params}) do
    canned_response = CannedResponses.get_canned_response!(id)

    with %{account_id: account_id} <- conn.assigns.current_user,
         params <- canned_response_params |> Map.merge(%{"account_id" => account_id}),
         {:ok, %CannedResponse{} = canned_response} <-
           CannedResponses.update_canned_response(canned_response, params) do
      render(conn, "show.json", canned_response: canned_response)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    canned_response = CannedResponses.get_canned_response!(id)

    with {:ok, %CannedResponse{}} <- CannedResponses.delete_canned_response(canned_response) do
      send_resp(conn, :no_content, "")
    end
  end
end
