defmodule ExManifestApiWeb.ResourceController do
  use ExManifestApiWeb, :controller
  alias ExManifestApi.{Repo, Resource}
  def manifest(conn, %{"id" => id}) do
    resource = Resource |> Repo.get!(id)
    render(conn, %{resource: resource})
  end
end
