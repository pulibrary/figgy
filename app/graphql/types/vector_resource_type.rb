# frozen_string_literal: true

class Types::VectorResourceType < Types::BaseObject
  implements Types::Resource

  field :source_metadata_identifier, String, null: true

  def label
    Array.wrap(object.title).first
  end

  def source_metadata_identifier
    Array.wrap(object.source_metadata_identifier).first
  end

  # Vector thumbnails are stored locally and not on the image server. Currently
  # we don't have the use case for implementing this.
  def thumbnail
    nil
  end
end
