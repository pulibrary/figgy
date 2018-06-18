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
      return if new_collection_record
      members.each do |member|
        propagate_read_groups(member)
        propagate_state_for_related(member)
        persister.save(resource: member)
      end
    end

    private

      def propagate_read_groups(member)
        return unless change_set.respond_to?(:read_groups) && change_set.read_groups
        member.read_groups = change_set.read_groups
      end

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
        change_set.respond_to?(:state) && change_set.state && resource.respond_to?(:state) && valid_states(resource).include?(translated_state_for(resource))
      end

      # Propagate or set the state for a related resource (e. g. a member or parent resource)
      # @param resource [Valkyrie::Resource] the related resource
      def propagate_state_for_related(resource)
        return unless should_set_state_for?(resource)
        resource.state = translated_state_for(resource)
        # save it through the change set persister so it can mint an ark if needed, emit rabbitmq messages, etc
        resource_change_set = DynamicChangeSet.new(resource)
        resource_change_set.validate(state: translated_state_for(resource))
        change_set_persister.save(change_set: resource_change_set)
      end

      # Retrieve the member resource for the resource in the ChangeSet
      # (This excludes FileSets)
      # @return [Array<Valkyrie::Resource>]
      def members
        wayfinder = Wayfinder.for(change_set.resource)
        if wayfinder.respond_to?(:members)
          wayfinder.members.select { |x| !x.is_a?(FileSet) }
        else
          []
        end
      end

      # it doesn't have members yet if it is just now being created
      def new_collection_record
        change_set.model.is_a?(Collection) && change_set.model.id.nil?
      end
  end
end
