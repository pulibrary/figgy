defmodule FigxWeb.ManifestsView do
  use FigxWeb, :view

  # manifest is an ecto Resource object
  def render("show.json", %{resource: resource}) do
    # Manifester.from_resource(resource)
    %{
      "@context": "http://iiif.io/api/presentation/2/context.json",
      "@id": resource.id,
      "@type": "sc:Collection",
      label: resource.metadata["title"]
    }
  end
end
