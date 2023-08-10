# frozen_string_literal: true
module ChangeSetWorkflow
  extend ActiveSupport::Concern
  included do
    property :state, multiple: false, required: true, default: workflow_class.aasm.initial_state.to_s
    property :workflow_note, multiple: true, required: false, default: []
    property :new_workflow_note_attributes, virtual: true

    def new_workflow_note_attributes=(attributes)
      return unless new_workflow_note.validate(attributes)
      new_workflow_note.sync
      workflow_note << new_workflow_note.model
    end

    # Default is set this way so that the WorkflowNoteChangeSet validations don't
    # show in the nested form.
    def new_workflow_note
      @new_workflow_note ||= ChangeSet.for(WorkflowNote.new)
    end

    def workflow
      workflow_class.new(Array.wrap(state).first)
    end

    def workflow_class
      self.class.workflow_class
    end

    def state_changed?
      # conditional assignment makes this true if it has ever been true, to allow seeing the change after sync
      @state_changed ||= changed?(:state) && !old_state.nil? && old_state != new_state
    end

    def new_state
      @new_state ||= Array.wrap(state).first
    end

    def old_state
      @old_state ||= Array.wrap(model.state).first
    end
  end
end
