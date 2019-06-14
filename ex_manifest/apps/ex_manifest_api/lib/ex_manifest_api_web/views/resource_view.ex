defmodule ExManifestApiWeb.ResourceView do
  use ExManifestApiWeb, :view

  def render("manifest.json", %{resource: resource}) do
    resource
    |> ExManifestApi.Manifest.to_manifest
    |> ExIiifManifest.generate_manifest
  end
end
