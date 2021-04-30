defmodule FigxWeb.ManifestsView do
  use FigxWeb, :view

  # manifest is an ecto Resource object
  def render("show.json", %{resource: resource}) do
    # Manifester.from_resource(resource)
    %{
      id: resource.id,
      label: resource.metadata["title"]
    }
  end
end
