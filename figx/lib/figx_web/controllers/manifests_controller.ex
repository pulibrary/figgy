defmodule FigxWeb.ManifestsController do
  use FigxWeb, :controller

  def show(conn, _params) do
    # TODO: fetch resource
    render(conn, "show.json", %{resource: nil})
  end
end
