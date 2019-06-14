defmodule ExIiifManifest.Endpoint do
  @moduledoc """
  Documentation for ExIiifManifest.Endpoint
  """
  @derive Jason.Encoder
  defstruct [
    :"@id",
    :"@type",
    :profile
  ]
end
