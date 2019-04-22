# frozen_string_literal: true
# Models events which modify resources

class Event < Valkyrie::Resource
  attribute :type
  attribute :status
  attribute :resource_id
  attribute :child_property
  attribute :child_id
  attribute :message
end
