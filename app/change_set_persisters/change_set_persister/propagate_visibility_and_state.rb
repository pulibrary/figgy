# frozen_string_literal: true
class ChangeSetPersister
  # Ensures that member resources inherit the visibility set on their parents
  # Also ensures that member resources have a state set which is appropriate to their Class
  #
  # Different resource types have different propagation behavior.
  #
  # 1. Most resources propagate state/visibility to their
  # children - if a parent is marked complete or set to private, its children
  # are marked complete or set to private. This is mostly used for Multivolume Works.
  #
  # 2. EphemeraProjects are more like collections from a workflow perspective.
  # If a project is marked complete or set to private, it doesn't propagate to
  # any of its members.
  #
  # 3. EphemeraBoxes are like collections with unique membership (one box per
  # folder), but with the ability to bulk complete all
  # children when the box's `all_in_production` state is set. So state
  # propagates (when `all_in_production` is set, all box children are marked
  # complete), but visibility does not (a folder might need to be private
  # independent of box state.)
  #
  # 4. Collections don't propagate anything, because objects can be members of
  # multiple collections so it can't act as an authority.
  #
  # TODO: See about cleaning up these workflows to make them more standard.
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
      return if collection_record
      return if ephemera_project
      return if numismatics_issue
      return if numismatics_reference
      members.each do |member|
        resource_change_set = ChangeSet.for(member)
        resource_change_set = propagate_visibility(resource_change_set)
        resource_change_set = propagate_state_for_related(resource_change_set)
        # we need to save these through the change set persister so the member
        #   can mint an ark, emit rabbitmq messages, copy access to read_groups, etc.
        if resource_change_set.changed?
          change_set_persister.save(change_set: resource_change_set)
        end
      end
    end

    private

      # set visibility on most resources; VisibilityProperty concern will make necessary changes on read_groups
      def propagate_visibility(member_change_set)
        return member_change_set unless member_change_set.inherit_visibility_from_parent?
        return propagate_read_groups(member_change_set) unless change_set.respond_to?(:visibility) && change_set.visibility && member_change_set.respond_to?(:visibility=)
        member_change_set.validate(visibility: change_set.visibility)
        member_change_set
      end

      # when there's no visiblity property (e.g. for a FileSet), set directly on read groups
      def propagate_read_groups(member_change_set)
        return member_change_set unless member_change_set.respond_to?(:read_groups) && change_set.respond_to?(:read_groups) && change_set.read_groups
        member_change_set.validate(read_groups: change_set.read_groups)
        member_change_set
      end

      # Construct the workflow for a related resource
      # @param related_resource [Valkyrie::Resource] resource related to the ChangeSet resource
      # @return [BaseWorkflow]
      def related_workflow(related_resource)
        related_resource_state = Array.wrap(related_resource.state).first
        ChangeSet.for(related_resource).workflow_class.new(related_resource_state)
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
      def propagate_state_for_related(member_change_set)
        return member_change_set unless should_set_state_for?(member_change_set.resource)
        member_change_set.validate(state: translated_state_for(member_change_set.resource))
        member_change_set
      end

      # Retrieve the member resource for the resource in the ChangeSet
      # @return [Array<Valkyrie::Resource>]
      def members
        wayfinder = Wayfinder.for(change_set.resource)
        if wayfinder.respond_to?(:members)
          wayfinder.members
        else
          []
        end
      end

      def collection_record
        change_set.model.is_a?(Collection)
      end

      def ephemera_project
        change_set.model.is_a?(EphemeraProject)
      end

      def numismatics_issue
        change_set.model.is_a?(Numismatics::Issue)
      end

      def numismatics_reference
        change_set.model.is_a?(Numismatics::Reference)
      end
  end
end
