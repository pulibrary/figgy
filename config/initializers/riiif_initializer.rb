# frozen_string_literal: true
require 'mini_magick'
Riiif::Image.file_resolver = RiiifResolver.new
Riiif::Image.file_resolver.base_path = Figgy.config['derivative_path']
Riiif::Image.info_service = lambda do |id, file|
  file_metadata = Valkyrie.config.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(id))
  file = Valkyrie::StorageAdapter.find_by(id: file_metadata.file_identifiers.first)
  image = MiniMagick::Image.new(file.io.path)
  height = file_metadata.height.first || image.height
  width = file_metadata.width.first || image.width
  { height: height, width: width }
end
