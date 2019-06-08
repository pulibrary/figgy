defmodule ExIiifManifestTest do
  use ExUnit.Case
  doctest ExIiifManifest

  test "generate_manifest" do
    resource = %ExIiifManifest.Resource{
      id: "https://test.example.com/1",
      viewingDirection: "left-to-right",
      label: "My Manifest"
    }

    output = ExIiifManifest.generate_manifest(resource)
    assert %ExIiifManifest.Manifest{} = output
    assert %{id: "https://test.example.com/1"} = output
    assert %{type: "Manifest"} = output

    assert %{
             "@context": [
               "http://www.w3.org/ns/anno.jsonld",
               "http://iiif.io/api/presentation/3/context.json"
             ]
           } = output

    assert %{viewingDirection: "left-to-right"} = output
    assert %{label: %{"@none": ["My Manifest"]}} = output
  end
end
