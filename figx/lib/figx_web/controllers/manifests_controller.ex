defmodule FigxWeb.ManifestsController do
  use FigxWeb, :controller

  def show(conn, %{"id" => id}) do
    resource = Figx.Repo.get_resource(id)
    render_resource(conn, resource)
  end

  def render_resource(conn, resource = %{internal_resource: "Collection"}) do
    render(conn, "show.json", %{resource: resource})
  end

  def render_resource(conn, resource) do
    conn
    |> send_resp(400, "")
  end
end
