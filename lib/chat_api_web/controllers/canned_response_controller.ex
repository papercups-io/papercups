defmodule ChatApiWeb.CannedResponseController do
  use ChatApiWeb, :controller

  alias ChatApi.CannedResponses
  alias ChatApi.CannedResponses.CannedResponse

  action_fallback ChatApiWeb.FallbackController

  @unauthorized_actions [:index, :create]

  plug :get_canned_response when action not in @unauthorized_actions

  plug Bodyguard.Plug.Authorize,
       [
         policy: CannedResponses.Policy,
         action: :get_canned_response!,
         user: {__MODULE__, :current_user},
         params: {__MODULE__, :extract_canned_response},
         fallback: ChatApiWeb.FallbackController
       ]
       when action not in @unauthorized_actions

  # Helper for the Authorize plug
  def current_user(conn), do: conn.assigns.current_user
  def extract_canned_response(conn), do: conn.assigns.current_canned_response

  defp get_canned_response(conn, _) do
    current_canned_response = CannedResponses.get_canned_response!(conn.params["id"])
    assign(conn, :current_canned_response, current_canned_response)
  end

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
  def show(conn, _params) do
    render(conn, "show.json", canned_response: conn.assigns.current_canned_response)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"canned_response" => canned_response_params}) do
    with {:ok, %CannedResponse{} = updated_canned_response} <-
           CannedResponses.update_canned_response(
             conn.assigns.current_canned_response,
             canned_response_params
           ) do
      render(conn, "show.json", canned_response: updated_canned_response)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    with {:ok, %CannedResponse{}} <-
           CannedResponses.delete_canned_response(conn.assigns.current_canned_response) do
      send_resp(conn, :no_content, "")
    end
  end
end
