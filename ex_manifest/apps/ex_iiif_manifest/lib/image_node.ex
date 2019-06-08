defmodule ExIiifManifest.ImageNode do
  @moduledoc """
  Documentation for ExIiifManifest.ImageNode
  """
  defstruct [
    :id,
    :download_path,
    :label,
    :width,
    :height,
    :format,
    :iiif_endpoint
  ]
end
