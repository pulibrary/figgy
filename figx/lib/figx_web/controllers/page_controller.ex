defmodule FigxWeb.PageController do
  use FigxWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
