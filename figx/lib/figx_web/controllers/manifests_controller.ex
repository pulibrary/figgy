defmodule FigxWeb.ManifestsController do
  use FigxWeb, :controller

  def show(conn, %{"id" => id}) do
    resource = Figx.Repo.get_resource(id)
    render(conn, "show.json", %{resource: resource})
  end
end
