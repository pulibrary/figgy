defmodule FigxWeb.ManifestsController do
  use FigxWeb, :controller
  alias Figx.Manifest

  def show(conn, %{"id" => id}) do
    resource = Manifest.get(id)
    render_resource(conn, resource)
  end

  def render_resource(conn, resource = %{"@type": "sc:Collection"}) do
    render(conn, "show.json", %{resource: resource})
  end

  def render_resource(conn, _resource) do
    conn
    |> send_resp(400, "")
  end
end
