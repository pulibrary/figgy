# frozen_string_literal: true

class WorkflowRegistry
  class EntryNotFound < StandardError; end

  class_attribute :hash
  self.hash = {}

  def self.register(resource_class:, workflow_class:)
    hash[resource_class] = workflow_class
    true
  end

  def self.workflow_for(resource_class)
    hash.fetch(resource_class)
  rescue KeyError
    raise EntryNotFound, resource_class
  end
end
