defmodule ChatApiWeb.NoteController do
  use ChatApiWeb, :controller

  alias ChatApi.Notes
  alias ChatApi.Notes.Note

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, %{"customer_id" => customer_id} = note_params) do
    case note_params do
      %{"customer_id" => ^customer_id} ->
        with %{account_id: account_id} <- conn.assigns.current_user do
          notes = Notes.list_notes_for_customer(%{account_id: account_id, customer_id: customer_id})
          render(conn, "index.json", notes: notes)
        end

      _ ->
        conn
        |> put_status(400)
        |> json(%{
          error: %{
            status: 400,
            message: "Please provide a customer_id"
          }
        })
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"note" => note_params}) do
    %{"body" => body, "customer_id" => customer_id} = note_params

    with %{account_id: account_id, id: author_id} <- conn.assigns.current_user do
      {:ok, %Note{} = note} = Notes.create_note(%{
         body: body,
         customer_id: customer_id,
         account_id: account_id,
         author_id: author_id
       })

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
