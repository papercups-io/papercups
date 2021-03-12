defmodule ChatApiWeb.CannedResponseController do
  use ChatApiWeb, :controller

  alias ChatApi.CannedResponses
  alias ChatApi.CannedResponses.CannedResponse

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    canned_responses = CannedResponses.list_canned_responses()
    render(conn, "index.json", canned_responses: canned_responses)
  end

  def create(conn, %{"canned_response" => canned_response_params}) do
    with {:ok, %CannedResponse{} = canned_response} <-
           CannedResponses.create_canned_response(canned_response_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.canned_response_path(conn, :show, canned_response))
      |> render("show.json", canned_response: canned_response)
    end
  end

  def show(conn, %{"id" => id}) do
    canned_response = CannedResponses.get_canned_response!(id)
    render(conn, "show.json", canned_response: canned_response)
  end

  def update(conn, %{"id" => id, "canned_response" => canned_response_params}) do
    canned_response = CannedResponses.get_canned_response!(id)

    with {:ok, %CannedResponse{} = canned_response} <-
           CannedResponses.update_canned_response(canned_response, canned_response_params) do
      render(conn, "show.json", canned_response: canned_response)
    end
  end

  def delete(conn, %{"id" => id}) do
    canned_response = CannedResponses.get_canned_response!(id)

    with {:ok, %CannedResponse{}} <- CannedResponses.delete_canned_response(canned_response) do
      send_resp(conn, :no_content, "")
    end
  end
end
