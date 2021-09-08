defmodule Figx.Manifest do
  alias Figx.{Repo, Resource, Collection}

  def get(id) do
    Repo.get(Resource, id)
    |> from_resource
  end

  def from_resource(resource = %{internal_resource: "Collection"}) do
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
  def from_resource(_resource), do: %{}

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
    Collection.members(resource.id)
    |> Enum.map(&render_collection_member/1)
  end

  def render_collection_member(resource = %Resource{}) do
    %{
       "@context" => "http://iiif.io/api/presentation/2/context.json",
       "@type" => "sc:Manifest",
       "@id" => "#{FigxWeb.Endpoint.url()}/concern/#{Macro.underscore(resource.internal_resource)}s/#{resource.id}/manifest",
      "label" => resource |> Resource.title,
      "description" => resource |> Resource.description
    }
  end
end
