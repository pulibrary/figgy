# frozen_string_literal: true
class ChangeSetPersister
  class PropagateVisibilityAndState
    attr_reader :change_set_persister, :change_set
    delegate :query_service, :persister, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return if !change_set.changed?(:visibility) && !change_set.changed?(:state)
      members.each do |member|
        member.read_groups = change_set.read_groups if change_set.read_groups
        propagate_state(member)
        persister.save(resource: member)
      end
    end

    def state_for_related(related)
      value = DynamicChangeSet.new(related).state_for_related change_set.model, change_set.state
      value.to_s
    end

    def should_set_state_for_related?(resource)
      change_set.state && resource.respond_to?(:state) && valid_states(resource).include?(state_for_related(resource))
    end

    # Propagate or set the state for a related resource (e. g. a member or parent resource)
    def propagate_state(resource)
      resource.state = state_for_related(resource) if should_set_state_for_related?(resource)
    end

    def members
      found = query_service.find_members(resource: change_set.resource) || []
      found.select do |x|
        !x.is_a?(FileSet)
      end
    end

    def valid_states(member)
      DynamicChangeSet.new(member).workflow_class.new.valid_states
    end
  end
end
