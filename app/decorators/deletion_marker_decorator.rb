# frozen_string_literal: true
class DeletionMarkerDecorator < Valkyrie::ResourceDecorator
  display :resource_id,
          :resource_title,
          :original_filename,
          :parent_id
end
