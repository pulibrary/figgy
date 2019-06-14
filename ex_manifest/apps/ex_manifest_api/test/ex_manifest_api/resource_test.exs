defmodule ExManifestApiResourceTest do
  use ExUnit.Case
  alias ExManifestApi.{Repo, Resource, Manifest}
  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end
  test "converting a resource to a manifest" do
    {:ok, file_set} = Repo.insert(%Resource{
      internal_resource: "FileSet",
      metadata: %{
        title: ["Page 1"],
        file_metadata: [
          %{
            id: [%{id: "file_metadata_id"}],
            use: [%{"@id": "http://pcdm.org/use#OriginalFile"}],
            mime_type: ["image/tiff"],
            height: ["1000"],
            width: ["500"]
          },
          %{
            id: %{id: "file_metadata_id_2"},
            use: [%{"@id": "http://pcdm.org/use#ServiceFile"}],
            mime_type: ["image/jp2"],
            file_identifiers: [%{id: "disk://01/02/03/derivative.jp2"}]
          }
        ]
      }
    })
    {:ok, scanned_resource} = Repo.insert(%Resource{
      internal_resource: "ScannedResource",
      metadata: %{
        title: ["Test Title"],
        member_ids: [%{id: file_set.id}]
      }
    })

    scanned_resource = Repo.get!(Resource, scanned_resource.id)
    output = scanned_resource |> Manifest.to_manifest

    assert output.id == "http://localhost:4002/#{scanned_resource.id}/manifest"
    assert output.label == "Test Title"
    assert length(output.canvas_nodes) == 1

    %{canvas_nodes: [canvas_node]} = output

    assert canvas_node.id == "http://localhost:4002/#{scanned_resource.id}/manifest/canvas/#{file_set.id}"
    assert canvas_node.format == "image/jpeg"
    assert canvas_node.width == "500"
    assert canvas_node.height == "1000"
    assert canvas_node.label == "Page 1"
    assert canvas_node.download_path == "http://localhost:3000/image-service/#{file_set.id}/full/!1000,/0/default.jpg"

    assert %{iiif_endpoint: endpoint = %ExIiifManifest.Endpoint{}} = canvas_node
    assert Map.get(endpoint, :"@type") == "ImageService2"
    assert endpoint.profile == "http://iiif.io/api/image/2/level2.json"
    assert Map.get(endpoint, :"@id") == "http://localhost:3000/image-service/#{file_set.id}"
  end
end
