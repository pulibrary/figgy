defmodule ExIiifManifest.ImageNode do
  @moduledoc """
  Documentation for ExIiifManifest.ImageNode
  """
  defstruct [
    :id,
    :label,
    :width,
    :height,
    :format,
    :iiif_endpoint,
    type: "Image"
  ]
end
