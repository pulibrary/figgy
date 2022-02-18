# frozen_string_literal: true

class PreservationObjectWayfinder < BaseWayfinder
  relationship_by_property :preserved_resources, property: :preserved_object_id, singular: true
end
