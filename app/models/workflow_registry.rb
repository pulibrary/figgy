# frozen_string_literal: true

# Provides access to a workflow given a resource class and
#   provides data about workflows in agregate
class WorkflowRegistry
  class EntryNotFound < StandardError; end

  # @return array of strings
  def self.all_states
    workflows.map { |klass| klass.new(nil).valid_states }.flatten.uniq
  end

  # @return array of strings
  def self.public_read_states
    workflows.map(&:public_read_states).flatten.uniq
  end

  # If the test for this fails you may be tempted to make this implementation
  # `BaseWorkflow.descendents`, but it won't work in Development because of lazy
  # loading.
  def self.workflows
    [BoxWorkflow, FolderWorkflow, GeoWorkflow, BookWorkflow, DraftCompleteWorkflow]
  end
end
