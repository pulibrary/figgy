defmodule ExManifestApi.Manifest do
  @moduledoc """
  Documentation for ExManifestApi.Manifest
  """
  import ExManifestApi.Resource.Query

  def to_manifest(resource) do
    %ExIiifManifest.Resource{
      id: resource.id |> to_manifest_url,
      label: hd(resource.metadata.title),
      canvas_nodes: resource |> members |> Enum.map(&to_image_node(resource, &1))
    }
  end

  defp to_manifest_url(id) do
    "https://test.com/#{id}/manifest"
  end

  defp to_manifest_url(parent_id, canvas_id) do
    "#{to_manifest_url(parent_id)}/canvas/#{canvas_id}"
  end

  defp to_image_node(parent_resource, file_set = %{internal_resource: "FileSet", metadata: metadata}) do
    %ExIiifManifest.ImageNode{
      id: to_manifest_url(parent_resource.id, file_set.id),
      format: "image/jpeg",
      width: file_set |> original_file |> Map.get("width") |> hd,
      height: file_set |> original_file |> Map.get("height") |> hd,
      label: metadata |> Map.get("title") |> hd,
      download_path: file_set |> download_path,
      iiif_endpoint: file_set |> endpoint
    }
  end

  defp original_file(%{metadata: %{"file_metadata" => file_metadata}}) do
    file_metadata
    |> Enum.find(&original_file?/1)
  end

  defp original_file?(%{"use" => [%{"@id" => "http://pcdm.org/use#OriginalFile"}]}),
    do: true

  defp original_file?(%{}), do: false

  defp derivative_file(%{metadata: %{"file_metadata" => file_metadata}}) do
    file_metadata
    |> Enum.find(&derivative_file?/1)
  end

  defp derivative_file?(%{"use" => [%{"@id" => "http://pcdm.org/use#ServiceFile"}]}),
    do: true

  defp derivative_file?(%{}), do: false

  defp download_path(file_set = %{id: resource_id}) do
    file_id = file_set
         |> derivative_file
         |> Map.get("id")
         |> hd
         |> Map.get("id")
    "https://test.com/downloads/#{resource_id}/file/#{file_id}"
  end

  defp endpoint(file_set) do
    %ExIiifManifest.Endpoint{
      id: file_set |> derivative_file |> image_service_path,
      type: "ImageService2",
      profile: "level2"
    }
  end

  defp image_service_path(%{"file_identifiers" => [%{"id" => image_id}]}) do
    id = image_id |> String.replace("disk://", "") |> String.replace("/", "%2F")
    "http://imageservice.com/#{id}"
  end

end
