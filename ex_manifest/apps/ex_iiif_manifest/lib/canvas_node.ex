defmodule ExIiifManifest.CanvasNode do
  @moduledoc """
  Documentation for ExIiifManifest.CanvasNode
  """
  defstruct [
    :id,
    :label,
    :type,
    :width,
    :height,
    :format,
    :iiif_endpoint
  ]
end
