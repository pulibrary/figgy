defmodule Figx.Manifest do
  alias Figx.{Repo, Resource, Collection, Member}

  def get(id) do
    Repo.get(Resource, id)
    |> from_resource
  end

  def from_resource(resource = %{internal_resource: "Collection"}), do: from_collection(resource)
  def from_resource(resource = %{internal_resource: "EphemeraProject"}), do: from_collection(resource)
  def from_resource(_resource), do: %{}

  defp from_collection(resource) do
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
    |> put_if_present([:rendering], rendering(resource))
  end

  def rendering(%{metadata: %{"identifier" => [identifier | _rest]}}) do
    %{
        "@id" => "https://arks.princeton.edu/#{identifier}",
      "format" => "text/html"
    }
  end

  def rendering(_resource), do: nil

  def member_manifests(resource = %{internal_resource: "Collection"}) do
    Collection.members(resource.id)
    |> Enum.map(&render_collection_member/1)
  end
  def member_manifests(resource = %{internal_resource: "EphemeraProject"}) do
    Member.members(resource.id)
    |> Enum.map(&render_collection_member/1)
  end

  def render_collection_member(resource = %Resource{}) do
    %{
       "@context" => "http://iiif.io/api/presentation/2/context.json",
       "@type" => "sc:Manifest",
       "@id" => manifest_id(resource),
      "label" => resource |> Resource.title,
    }
    |> put_if_present(["description"], Resource.description(resource))
  end

  defp manifest_id(resource = %{internal_resource: "EphemeraBox"}) do
    manifest_id(resource |> Map.put(:internal_resource, "EphemeraFolder"))
  end
  defp manifest_id(resource) do
    "#{FigxWeb.Endpoint.url()}/concern/#{Macro.underscore(resource.internal_resource)}s/#{resource.id}/manifest"
  end

  defp put_if_present(map, _, ""), do: map
  defp put_if_present(map, _, []), do: map
  defp put_if_present(map, _, [""]), do: map
  defp put_if_present(map, _, nil), do: map
  defp put_if_present(map, keys, value) do
    map
    |> put_in(keys, value)
  end
end
