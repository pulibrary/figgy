# frozen_string_literal: true

# Class for ImageMagick identify based file characterization service
class IdentifyFileCharacterizationService < TikaFileCharacterizationService
  attr_reader :mime_types, :file_node, :persister

  def initialize(file_node:, persister:)
    @file_node = file_node
    @persister = persister
    @mime_types = {
      "TIFF": "image/tiff"
    }.stringify_keys
  end

  def json_output
    raw_output = `identify #{filename}`
    (_, type, dim,) = raw_output.split(" ")
    dimensions = dim.split("x")
    {
      "Content-Length": File.size(filename),
      "Content-Type": mime_types[type],
      "tiff:ImageWidth": dimensions[0],
      "tiff:ImageLength": dimensions[1]
    }.stringify_keys
  end
end
