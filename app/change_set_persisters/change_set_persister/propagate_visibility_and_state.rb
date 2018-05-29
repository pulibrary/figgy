# frozen_string_literal: true
class ChangeSetPersister
  # Ensures that member resources inherit the visibility set on their parents
  # Also ensures that member resources have a state set which is appropriate to their Class
  class PropagateVisibilityAndState
    attr_reader :change_set_persister, :change_set
    delegate :query_service, :persister, to: :change_set_persister

    # Constructor
    # @param change_set_persister [ChangeSetPersister]
    # @param change_set [Valkyrie::ChangeSet]
    # @param post_save_resource [Valkyrie::Resource]
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    # Execute the handler
    def run
      members.each do |member|
        member.read_groups = change_set.read_groups if change_set.read_groups
        propagate_state_for_related(member)
        persister.save(resource: member)
      end
    end

    private

      # Construct the workflow for a related resource
      # @param related_resource [Valkyrie::Resource] resource related to the ChangeSet resource
      # @return [BaseWorkflow]
      def related_workflow(related_resource)
        related_resource_state = Array.wrap(related_resource.state).first
        DynamicChangeSet.new(related_resource).workflow_class.new(related_resource_state)
      end

      # Retrieve all possible valid workflow states for a resource
      # @param member [Valkyrie::Resource]
      # @return [Array<Symbol>]
      def valid_states(member)
        related_workflow(member).valid_states
      end

      # Construct a workflow with the state of the workflow currently in the ChangeSet
      # @return [BaseWorkflow]
      def changed_workflow
        changed_state = Array.wrap(change_set.state).first
        change_set.workflow_class.new(changed_state)
      end

      # Translate the workflow states between a resource and the one currently in the ChangeSet
      # @param resource [Valkyrie::Resource]
      # @return [String] the translated workflow state
      def translated_state_for(resource)
        state_value = related_workflow(resource).translate_state_from(changed_workflow)
        state_value.to_s
      end

      # Determine whether or not the workflow state in the ChangeSet should update the workflow state in a related resource
      # @param resource [Valkyrie::Resource]
      # @return [TrueClass, FalseClass]
      def should_set_state_for?(resource)
        change_set.state && resource.respond_to?(:state) && valid_states(resource).include?(translated_state_for(resource))
      end

      # Propagate or set the state for a related resource (e. g. a member or parent resource)
      # @param resource [Valkyrie::Resource] the related resource
      def propagate_state_for_related(resource)
        resource.state = translated_state_for(resource) if should_set_state_for?(resource)
      end

      # Retrieve the member resource for the resource in the ChangeSet
      # (This excludes FileSets)
      # @return [Array<Valkyrie::Resource>]
      def members
        found = query_service.find_members(resource: change_set.resource) || []
        found.select do |x|
          !x.is_a?(FileSet)
        end
      end
  end
end
