defmodule ChatApiWeb.UploadView do
  use ChatApiWeb, :view
  alias ChatApiWeb.UploadView

  def render("show.json", %{upload: upload}) do
    %{data: render_one(upload, UploadView, "upload.json")}
  end

  def render("upload.json", %{upload: upload}) do
    %{id: upload.id, file_url: upload.file_url}
  end
end
