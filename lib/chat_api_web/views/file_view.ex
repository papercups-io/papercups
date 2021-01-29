defmodule ChatApiWeb.FileView do
  use ChatApiWeb, :view
  alias ChatApiWeb.FileView

  def render("show.json", %{file: file}) do
    %{data: render_one(file, FileView, "file.json")}
  end

  def render("file.json", %{file: file}) do
    %{
      id: file.id,
      object: "file",
      file_url: file.file_url,
      content_type: file.content_type,
      filename: file.filename
    }
  end
end
