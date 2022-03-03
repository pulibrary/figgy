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
          :service_targets,
          :error_message

  delegate :collections, :preservation_objects, to: :wayfinder

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

  def cloud_fixity_success_of(file_id)
    cloud_fixity_events_for(file_id).max_by(&:created_at)&.status
  end

  def cloud_fixity_last_success_date_of(file_id)
    cloud_fixity_events_for(file_id).select { |e| e.status == "SUCCESS" }.map(&:created_at).max || "n/a"
  end

  def custom_queries
    Valkyrie.config.metadata_adapter.query_service.custom_queries
  end

  def cloud_fixity_events_for(file_id)
    preservation_id = preservation_id_of(file_id)
    return [] if preservation_id.blank?
    custom_queries.find_by_property(property: :child_id, value: preservation_id)
  end

  def preservation_id_of(file_id)
    preservation_binaries.select { |b| b.preservation_copy_of_id == file_id }.map(&:id).first
  end

  def preservation_binaries
    preservation_objects.first&.binary_nodes || []
  end
end
