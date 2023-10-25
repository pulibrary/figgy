# frozen_string_literal: true
class DeletionMarkerDecorator < Valkyrie::ResourceDecorator
  display :resource_id,
          :resource_title,
          :resource_type,
          :resource_identifier,
          :resource_source_metadata_identifier,
          :resource_local_identifier,
          :member_of_collection_titles,
          :depositor,
          :original_filename,
          :parent_id
end
