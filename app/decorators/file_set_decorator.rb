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
          :bounds,
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
    events = cloud_fixity_events_for(file_id)
    if events.present?
      events.find(&:current?)&.status
    elsif preservation_object_for(file_id)
      Event::SUCCESS
    end
  end

  def cloud_fixity_last_success_date_of(file_id)
    events = cloud_fixity_events_for(file_id)
    if events.present?
      format_date(events.select(&:successful?).map(&:created_at).max)
    else
      preservation_object = preservation_object_for(file_id)
      format_date(preservation_object&.created_at)
    end
  end

  def local_fixity_success_of(file_id)
    return "n/a" unless fixity_checked_file_ids.include?(file_id)
    event_status = custom_queries.find_by_property(
      model: Event,
      property: :metadata,
      value: { current: true, resource_id: id, child_id: file_id }
    ).first&.status
    event_status || "n/a"
  end

  def local_fixity_last_success_date_of(file_id)
    return "n/a" unless fixity_checked_file_ids.include?(file_id)
    event_date = custom_queries.find_by_property(
      model: Event,
      property: :metadata,
      value: { status: Event::SUCCESS, resource_id: id, child_id: file_id }
    ).map(&:created_at).max
    format_date(event_date)
  end

  def format_date(date)
    if date
      date.strftime("%b %d, %Y @ %I:%M %P")
    else
      "n/a"
    end
  end

  def custom_queries
    Valkyrie.config.metadata_adapter.query_service.custom_queries
  end

  def cloud_fixity_events_for(file_id)
    preservation_id = preservation_id_of(file_id)
    return [] if preservation_id.blank?
    custom_queries.find_by_property(property: :child_id, value: preservation_id, model: Event)
  end

  def preservation_object_for(file_id)
    preservation_objects.find { |po| po.binary_nodes.find { |b| b.preservation_copy_of_id == file_id } }
  end

  def preservation_id_of(file_id)
    preservation_binaries.select { |b| b.preservation_copy_of_id == file_id }.map(&:id).first
  end

  def preservation_binaries
    preservation_objects.first&.binary_nodes || []
  end

  def bounds
    coords = super&.first
    return unless coords
    "North: #{coords[:north]}, East: #{coords[:east]}, South: #{coords[:south]}, West: #{coords[:west]}"
  end
end
