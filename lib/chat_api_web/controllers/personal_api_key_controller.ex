defmodule ChatApiWeb.PersonalApiKeyController do
  use ChatApiWeb, :controller

  alias ChatApi.ApiKeys
  alias ChatApi.ApiKeys.PersonalApiKey

  action_fallback ChatApiWeb.FallbackController

  def index(
        %{assigns: %{current_user: %{account_id: account_id, id: user_id}}} = conn,
        _params
      ) do
    personal_api_keys = ApiKeys.list_personal_api_keys(user_id, account_id)
    render(conn, "index.json", personal_api_keys: personal_api_keys)
  end

  def create(%{assigns: %{current_user: %{account_id: account_id, id: user_id}}} = conn, %{
        "label" => personal_api_key_label
      }) do
    with params <- %{
           label: personal_api_key_label,
           user_id: user_id,
           account_id: account_id,
           value:
             ApiKeys.generate_random_token(personal_api_key_label,
               user_id: user_id,
               account_id: account_id
             )
         },
         {:ok, %PersonalApiKey{} = personal_api_key} <-
           ApiKeys.create_personal_api_key(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.personal_api_key_path(conn, :show, personal_api_key))
      |> render("show.json", personal_api_key: personal_api_key)
    end
  end

  def show(conn, %{"id" => id}) do
    # TODO: filter by user_id/account_id?
    personal_api_key = ApiKeys.get_personal_api_key!(id)
    render(conn, "show.json", personal_api_key: personal_api_key)
  end

  def delete(conn, %{"id" => id}) do
    personal_api_key = ApiKeys.get_personal_api_key!(id)

    with {:ok, %PersonalApiKey{}} <- ApiKeys.delete_personal_api_key(personal_api_key) do
      send_resp(conn, :no_content, "")
    end
  end
end
