defmodule ExIiifManifestTest do
  use ExUnit.Case
  doctest ExIiifManifest

  test "generate_manifest" do
    resource = %ExIiifManifest.Resource{
      id: "https://test.example.com/1",
      viewingDirection: "left-to-right",
      label: "My Manifest",
      canvas_nodes: [
        %ExIiifManifest.ImageNode{
          id: "https://test.example.com/1/2",
          label: "Page 1",
          width: "1000",
          height: "500",
          format: "image/jpeg",
          download_path: "https://test.example.com/download/2",
          iiif_endpoint: %ExIiifManifest.Endpoint{
            id: "https://imageserver.com/1",
            type: "ImageService2",
            profile: "level2"
          }
        }
      ]
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

    %{items: items} = output
    assert length(items) == 1
    canvas = hd(items)
    assert %{id: "https://test.example.com/1/2"} = canvas
    assert %{type: "Canvas"} = canvas
    assert %{label: %{"@none": ["Page 1"]}} = canvas
    assert %{height: 500, width: 1000} = canvas

    %{items: items} = canvas
    assert length(items) == 1
    annotation = hd(items)
    assert %{type: "AnnotationPage"} = annotation
    assert %{
      items: [
        %{
          type: "Annotation",
          motivation: "painting",
          target: "https://test.example.com/1/2",
          body: %{
            id: "https://test.example.com/download/2",
            type: "Image",
            format: "image/jpeg",
            width: 1000,
            height: 500,
            service: %{
              id: "https://imageserver.com/1",
              type: "ImageService2",
              profile: "level2"
            }
          }
        }
      ]
    } = annotation
  end
end
