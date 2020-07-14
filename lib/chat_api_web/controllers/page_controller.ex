defmodule ChatApiWeb.PageController do
  use ChatApiWeb, :controller

  def index(conn, _params) do
    html(conn, File.read!("./priv/static/index.html"))
  end
end
