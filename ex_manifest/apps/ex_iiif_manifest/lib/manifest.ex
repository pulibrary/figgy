defmodule ExIiifManifest.Manifest do
  @moduledoc """
  Documentation for ExIiifManifest.Manifest
  """
  defstruct [
    :id,
    type: "Manifest",
    "@context": [
      "http://www.w3.org/ns/anno.jsonld",
      "http://iiif.io/api/presentation/3/context.json"
    ]
  ]
end
