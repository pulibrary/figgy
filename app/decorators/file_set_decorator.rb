# frozen_string_literal: true
class FileSetDecorator < Valkyrie::ResourceDecorator
  display :height,
          :width,
          :x_resolution,
          :y_resolution,
          :bits_per_sample,
          :mime_type,
          :size,
          :md5,
          :sha1,
          :sha256,
          :camera_model,
          :software,
          :geometry,
          :processing_note

  delegate :collections, to: :wayfinder

  def manageable_files?
    false
  end

  # TODO: Rename to decorated_parent
  def parent
    wayfinder.decorated_parent
  rescue ArgumentError
    nil
  end

  def collection_slugs
    []
  end
end
