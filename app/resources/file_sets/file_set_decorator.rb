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
          :cloud_fixity_status,
          :cloud_fixity_last_success,
          :camera_model,
          :software,
          :geometry,
          :processing_note,
          :barcode,
          :part,
          :transfer_notes,
          :error_message

  delegate :collections, :preservation_objects, to: :wayfinder

  def manageable_files?
    false
  end

  def cloud_fixity_status
    case cloud_fixity_status_raw
    when nil
      "in progress"
    when "FAILURE"
      "failed"
    when "SUCCESS"
      "succeeded"
    end
  end

  def cloud_fixity_status_raw
    return nil if cloud_fixity_events.empty?
    cloud_fixity_events.max(&:created_at)&.status
  end

  def cloud_fixity_last_success
    cloud_fixity_events.select { |e| e.status == "SUCCESS" }.map(&:created_at).max || "n/a"
  end

  def cloud_fixity_events
    return [] if preservation_objects.empty?
    @cloud_fixity_events ||= preservation_objects.first.decorate.events
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
