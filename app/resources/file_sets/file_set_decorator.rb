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
          :processing_note,
          :barcode,
          :part,
          :transfer_notes,
          :error_message

  delegate :collections, to: :wayfinder

  def manageable_files?
    false
  end

  # TODO: Rename to decorated_parent
  def parent
    object.try(:loaded)&.[](:parents)&.first || wayfinder.decorated_parent
  end

  def collection_slugs
    []
  end

  delegate :downloadable?, to: :parent
end
