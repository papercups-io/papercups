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

  # TODO: handle this in a "broadcast_controller" or something like that
  @spec send(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send(conn, %{"id" => id, "customers" => customer_ids}) do
    with %{account_id: account_id, email: email, id: user_id} <- conn.assigns.current_user,
         %{refresh_token: refresh_token} <-
           ChatApi.Google.get_support_gmail_authorization(account_id, user_id),
         %MessageTemplate{raw_html: raw_html, plain_text: plain_text} <-
           MessageTemplates.get_message_template!(id) do
      results =
        Enum.map(customer_ids, fn customer_id ->
          customer = ChatApi.Customers.get_customer!(customer_id)
          {:ok, text} = MessageTemplates.render(plain_text, customer)
          {:ok, html} = MessageTemplates.render(raw_html, customer)

          # TODO: figure out the best way to handle errors here
          ChatApi.Google.Gmail.send_message(refresh_token, %{
            to: customer.email,
            from: email,
            subject: "Test Papercups template",
            text: text,
            html: html
          })
        end)

      json(conn, %{ok: true, num_sent: length(results)})
    end
  end
end
