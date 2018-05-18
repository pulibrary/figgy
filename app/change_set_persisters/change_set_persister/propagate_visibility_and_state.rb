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
        propagate_state_for_related(member)
        persister.save(resource: member)
      end
    end

    def related_workflow(related_resource)
      related_resource_state = Array.wrap(related_resource.state).first
      DynamicChangeSet.new(related_resource).workflow_class.new(related_resource_state)
    end

    def valid_states(member)
      related_workflow(member).valid_states
    end

    def changed_workflow
      changed_state = Array.wrap(change_set.state).first
      change_set.workflow_class.new(changed_state)
    end

    def translated_state_for(resource)
      state_value = related_workflow(resource).translate_state_from(changed_workflow)
      state_value.to_s
    end

    def should_set_state_for?(resource)
      change_set.state && resource.respond_to?(:state) && valid_states(resource).include?(translated_state_for(resource))
    end

    # Propagate or set the state for a related resource (e. g. a member or parent resource)
    def propagate_state_for_related(resource)
      resource.state = translated_state_for(resource) if should_set_state_for?(resource)
    end

    def members
      found = query_service.find_members(resource: change_set.resource) || []
      found.select do |x|
        !x.is_a?(FileSet)
      end
    end
  end
end
