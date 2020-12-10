defmodule ChatApiWeb.NoteController do
  use ChatApiWeb, :controller

  alias ChatApi.Notes
  alias ChatApi.Notes.Note

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    notes = Notes.list_notes()
    render(conn, "index.json", notes: notes)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"note" => note_params}) do
    with {:ok, %Note{} = note} <- Notes.create_note(note_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.note_path(conn, :show, note))
      |> render("show.json", note: note)
    end
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    note = Notes.get_note!(id)
    render(conn, "show.json", note: note)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id, "note" => note_params}) do
    note = Notes.get_note!(id)

    with {:ok, %Note{} = note} <- Notes.update_note(note, note_params) do
      render(conn, "show.json", note: note)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    note = Notes.get_note!(id)

    with {:ok, %Note{}} <- Notes.delete_note(note) do
      send_resp(conn, :no_content, "")
    end
  end
end
