defmodule ChatApiWeb.NoteController do
  use ChatApiWeb, :controller

  alias ChatApi.Notes
  alias ChatApi.Notes.Note

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete])

  def authorize(conn, _) do
    id = conn.path_params["id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         note = %{account_id: ^account_id} <- Notes.get_note!(id) do
      assign(conn, :current_note, note)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, filters) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      notes = Notes.list_notes_by_account(account_id, filters)
      render(conn, "index.json", notes: notes)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"note" => note_params}) do
    %{"body" => body, "customer_id" => customer_id} = note_params

    with %{account_id: account_id, id: author_id} <- conn.assigns.current_user,
         {:ok, %Note{} = note} <-
           Notes.create_note(%{
             body: body,
             customer_id: customer_id,
             account_id: account_id,
             author_id: author_id
           }) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.note_path(conn, :show, note.id)
      )
      |> render("show.json", note: note)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _params) do
    render(conn, "show.json", note: conn.assigns.current_note)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"note" => note_params}) do
    note = conn.assigns.current_note

    with {:ok, %Note{} = note} <- Notes.update_note(note, note_params) do
      render(conn, "show.json", note: note)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    note = conn.assigns.current_note

    with {:ok, %Note{}} <- Notes.delete_note(note) do
      send_resp(conn, :no_content, "")
    end
  end
end
