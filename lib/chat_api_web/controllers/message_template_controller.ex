defmodule ChatApiWeb.MessageTemplateController do
  use ChatApiWeb, :controller

  alias ChatApi.MessageTemplates
  alias ChatApi.MessageTemplates.MessageTemplate

  action_fallback ChatApiWeb.FallbackController

  plug :authorize when action in [:show, :update, :delete]

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         message_template = %{account_id: ^account_id} <-
           MessageTemplates.get_message_template!(id) do
      assign(conn, :current_message_template, message_template)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      message_templates = MessageTemplates.list_message_templates(account_id)
      render(conn, "index.json", message_templates: message_templates)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"message_template" => message_template_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         {:ok, %MessageTemplate{} = message_template} <-
           message_template_params
           |> Map.merge(%{"account_id" => account_id})
           |> MessageTemplates.create_message_template() do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.message_template_path(conn, :show, message_template))
      |> render("show.json", message_template: message_template)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => _id}) do
    render(conn, "show.json", message_template: conn.assigns.current_message_template)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => _id, "message_template" => message_template_params}) do
    with {:ok, %MessageTemplate{} = message_template} <-
           MessageTemplates.update_message_template(
             conn.assigns.current_message_template,
             message_template_params
           ) do
      render(conn, "show.json", message_template: message_template)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => _id}) do
    with {:ok, %MessageTemplate{}} <-
           MessageTemplates.delete_message_template(conn.assigns.current_message_template) do
      send_resp(conn, :no_content, "")
    end
  end
end
