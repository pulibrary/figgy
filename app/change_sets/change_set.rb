# frozen_string_literal: true
class ChangeSet < Valkyrie::ChangeSet
  class_attribute :workflow_class
  def self.apply_workflow(workflow)
    self.workflow_class = workflow
    include(ChangeSetWorkflow)
  end

  def state_for_related(related_resource, related_state)
    klass = related_resource.class.to_s.to_sym
    state_value = Array.wrap(related_state).first
    state = state_value.to_sym
    workflow_class.state_for_related(klass: klass, state: state)
  end

  def prepopulate!
    super.tap do
      @_changes = Disposable::Twin::Changed::Changes.new
    end
  end
end
