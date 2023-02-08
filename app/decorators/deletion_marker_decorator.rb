# frozen_string_literal: true
class DeletionMarkerDecorator < Valkyrie::ResourceDecorator
  display :resource_id,
          :resource_title,
          :resource_type,
          :depositor,
          :original_filename,
          :parent_id
end
