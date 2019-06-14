defmodule ExIiifManifest do
  @moduledoc """
  Documentation for ExIiifManifest.
  """
  def generate_manifest(resource = %{}) do
    %ExIiifManifest.Manifest{}
    |> Map.put(:id, resource.id)
    |> apply_viewing_direction(resource)
    |> apply_label(resource)
    |> Map.put(:items, create_canvases(resource))
  end

  defp apply_viewing_direction(manifest, %{viewingDirection: direction}) do
    manifest
    |> Map.put(:viewingDirection, direction)
  end

  defp apply_label(manifest, %{label: label}) when is_list(label) do
    manifest
    |> Map.put(:label, %{"@none": label})
  end

  defp apply_label(manifest, %{label: label}) when is_binary(label) do
    apply_label(manifest, %{label: [label]})
  end

  defp create_canvases(%{canvas_nodes: nodes}) do
    nodes
    |> Enum.map(&create_canvas/1)
  end

  defp create_canvas(node = %ExIiifManifest.ImageNode{}) do
    %{
      id: node.id,
      type: "Canvas",
      height: node.height |> ensure_int,
      width: node.width |> ensure_int
    }
    |> apply_label(node)
    |> apply_annotation(node)
    |> apply_thumbnail(node)
  end

  defp apply_thumbnail(manifest, node = %ExIiifManifest.ImageNode{}) do
    manifest
    |> Map.put(:thumbnail, [create_thumbnail(node)])
  end

  defp create_thumbnail(node = %ExIiifManifest.ImageNode{}) do
    %{
      id: "#{Map.get(node.iiif_endpoint, :"@id")}/full/200,/0/default.jpg",
      type: "Image",
      service: [
        node.iiif_endpoint
      ]
    }
  end

  defp apply_annotation(manifest, node = %ExIiifManifest.ImageNode{}) do
    manifest
    |> Map.put(:items, [create_annotation(node)])
  end

  defp create_annotation(node = %ExIiifManifest.ImageNode{}) do
    %{
      type: "AnnotationPage",
      id: "#{node.id}/AnnotationPage",
      items: [
        %{
          id: "#{node.id}/Annotation",
          type: "Annotation",
          motivation: "painting",
          target: node.id,
          body: %{
            id: node.download_path,
            type: "Image",
            format: node.format,
            width: node.width |> ensure_int,
            height: node.height |> ensure_int,
            service: [node.iiif_endpoint]
          }
        }
      ]
    }
  end

  defp ensure_int(int) when is_integer(int) do
    int
  end
  defp ensure_int(int) when is_binary(int) do
    {parsed_int, _} = Integer.parse(int)
    parsed_int
  end
end
