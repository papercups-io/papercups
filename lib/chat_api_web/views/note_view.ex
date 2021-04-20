defmodule ChatApiWeb.NoteView do
  use ChatApiWeb, :view

  alias ChatApiWeb.{
    NoteView,
    UserView
  }

  alias ChatApi.Users.User

  def render("index.json", %{notes: notes}) do
    %{data: render_many(notes, NoteView, "note.json")}
  end

  def render("show.json", %{note: note}) do
    %{data: render_one(note, NoteView, "note.json")}
  end

  def render("note.json", %{note: note}) do
    %{
      id: note.id,
      object: "note",
      body: note.body,
      customer_id: note.customer_id,
      author_id: note.author_id,
      created_at: note.inserted_at,
      updated_at: note.updated_at
    }
    |> maybe_render_author(note)
  end

  defp maybe_render_author(json, %{author: author}) do
    case author do
      nil ->
        Map.merge(json, %{author: nil})

      %User{} = author ->
        Map.merge(json, %{author: render_one(author, UserView, "user.json")})

      _ ->
        json
    end
  end
end
