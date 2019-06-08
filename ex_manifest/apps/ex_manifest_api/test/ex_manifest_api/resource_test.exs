defmodule ExManifestApiResourceTest do
  use ExUnit.Case
  alias ExManifestApi.{Repo, Resource}
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
            height: ["500"],
            width: ["500"]
          },
          %{
            id: [%{id: "file_metadata_id_2"}],
            use: [%{"@id": "http://pcdm.org/use#ServiceFile"}],
            mime_type: ["image/jp2"]
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

    output = scanned_resource |> Resource.to_manifest

    assert output.id == "https://test.com/#{scanned_resource.id}/manifest"
    assert output.label == "Test Title"
    assert length(output.canvas_nodes) == 1
  end
end
