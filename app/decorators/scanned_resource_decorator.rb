# frozen_string_literal: true
class ScannedResourceDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:author, :internal_resource, :created_at, :updated_at]
end
