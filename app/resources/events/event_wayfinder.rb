# frozen_string_literal: true
class EventWayfinder < BaseWayfinder
  # All valid relationships for an Event
  relationship_by_property :modified_resources, property: :modified_resource_ids
end
