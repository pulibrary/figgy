# frozen_string_literal: true
class ChangeSet < Valkyrie::ChangeSet
  class_attribute :workflow_class
  def self.apply_workflow(workflow)
    self.workflow_class = workflow
    include(ChangeSetWorkflow)
  end

  # This property is set by ChangeSetPersister::CreateFile and is used to keep
  # track of which FileSets were created by the ChangeSetPersister as part of
  # saving this change_set. We may want to look into passing some sort of scope
  # around with the change_set in ChangeSetPersister instead, at some point.
  property :created_file_sets, virtual: true, multiple: true, required: false, default: []

  def initialize(*args)
    super.tap do
      fix_multivalued_keys
    end
  end

  # This is a temporary fix to deal with the fact that we have change sets which
  # are set to be singular when the model is set to be multiple. REMOVE THIS as
  # soon as the model has single-value fields in places where it makes sense.
  #
  # @todo: REMOVE THIS.
  def fix_multivalued_keys
    self.class.definitions.select { |_field, definition| definition[:multiple] == false }.each_key do |field|
      value = Array.wrap(send(field.to_s)).first
      send("#{field}=", value)
    end
    @_changes = Disposable::Twin::Changed::Changes.new
  end
end
