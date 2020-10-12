defmodule ChatApiWeb.TagController do
  use ChatApiWeb, :controller

  alias ChatApi.Tags
  alias ChatApi.Tags.Tag

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{current_user: %{account_id: account_id}}} = conn, _params) do
    tags = Tags.list_tags(account_id)

    render(conn, "index.json", tags: tags)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(%{assigns: %{current_user: %{account_id: account_id, id: creator_id}}} = conn, %{
        "tag" => tag_params
      }) do
    with {:ok, %Tag{} = tag} <-
           tag_params
           |> Map.merge(%{"creator_id" => creator_id, "account_id" => account_id})
           |> Tags.create_tag() do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.tag_path(conn, :show, tag))
      |> render("show.json", tag: tag)
    end
  end

  def show(conn, %{"id" => id}) do
    tag = Tags.get_tag!(id)
    render(conn, "show.json", tag: tag)
  end

  def update(%{assigns: %{current_user: %{account_id: account_id}}} = conn, %{
        "id" => id,
        "tag" => tag_params
      }) do
    tag = Tags.get_tag!(id)

    with updates <- Map.merge(tag_params, %{"account_id" => account_id}),
         {:ok, %Tag{} = tag} <- Tags.update_tag(tag, updates) do
      render(conn, "show.json", tag: tag)
    end
  end

  def delete(conn, %{"id" => id}) do
    tag = Tags.get_tag!(id)

    with {:ok, %Tag{}} <- Tags.delete_tag(tag) do
      send_resp(conn, :no_content, "")
    end
  end
end
