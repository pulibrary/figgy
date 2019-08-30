# frozen_string_literal: true
#
# A persistence handler for deleting references to an EphemeraTerm on delete.
class ChangeSetPersister
  class CleanupTerms
    attr_reader :change_set_persister, :change_set
    delegate :resource, to: :change_set
    delegate :query_service, to: :change_set_persister

    def initialize(change_set_persister:, change_set:)
      @change_set_persister = change_set_persister
      @change_set = change_set
    end

    def run
      return unless resource.is_a?(EphemeraTerm)
      resources = query_service.custom_queries.find_id_usage_by_model(id: resource.id, model: EphemeraFolder)
      change_sets = resources.map do |parent_resource, keys|
        parent_change_set = ChangeSet.for(parent_resource)
        keys.each do |key|
          parent_change_set.validate(key => (parent_resource[key] - [resource.id]))
        end
        parent_change_set
      end
      change_set_persister.save_all(change_sets: change_sets)
    end
  end
end
