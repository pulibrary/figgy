# frozen_string_literal: true
class DeletionMarkerDecorator < Valkyrie::ResourceDecorator
  display :resource_id,
          :resource_title,
          :resource_type,
          :resource_identifier,
          :resource_source_metadata_identifier,
          :resource_local_identifier,
          :depositor,
          :original_filename,
          :parent_id
end
