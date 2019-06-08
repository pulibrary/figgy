defmodule ExIiifManifest do
  @moduledoc """
  Documentation for ExIiifManifest.
  """
  def generate_manifest(resource = %{}) do
    %ExIiifManifest.Manifest{}
    |> Map.put(:id, resource.id)
    |> apply_viewing_direction(resource)
    |> apply_label(resource)
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
end
