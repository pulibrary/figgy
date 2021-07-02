defmodule FigxWeb.ManifestsView do
  use FigxWeb, :view

  # manifest is an ecto Resource object
  def render("show.json", %{resource: resource}) do
    # Manifester.from_resource(resource)
    %{
      "@context": "http://iiif.io/api/presentation/2/context.json",
      "@id": "#{FigxWeb.Endpoint.url()}/collections/#{resource.id}/manifest",
      "@type": "sc:Collection",
      label: resource.metadata["title"],
      description: resource.metadata["description"],
      metadata: [%{"label" => "Exhibit", "value" => resource.metadata["slug"]}],
      seeAlso: %{
        "@id" => "#{FigxWeb.Endpoint.url()}/catalog/#{resource.id}.jsonld",
        "format" => "application/ld+json"
      },
      manifests: member_manifests(resource)
    }
    |> add_rendering(resource)
  end

  # Add rendering property if the identifier property exists.
  def add_rendering(manifest, %{metadata: %{"identifier" => [identifier | _rest]}}) do
    manifest
    |> Map.put(
      :rendering,
      %{
        "@id" => "https://arks.princeton.edu/#{identifier}",
        "format" => "text/html"
      }
    )
  end

  def add_rendering(manifest, _resource), do: manifest

  def member_manifests(resource) do
    Figx.Repo.get_collection_members(resource.id)
    |> Enum.map(&render_collection_member/1)
  end

  def render_collection_member(resource = %Figx.Resource{}) do
    %{
       "@context" => "http://iiif.io/api/presentation/2/context.json",
       "@type" => "sc:Manifest",
       "@id" => "#{FigxWeb.Endpoint.url()}/concern/scanned_resources/#{resource.id}/manifest",
      "label" => resource.metadata["imported_metadata"] |> hd |> Map.get("title"),
      "description" => resource.metadata["imported_metadata"] |> hd |> Map.get("description")
    }
  end
end
