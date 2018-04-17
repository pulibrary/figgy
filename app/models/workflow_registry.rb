# frozen_string_literal: true

# Provides access to a workflow given a resource class and
#   provides data about workflows in agregate
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

  def self.unregister(resource_class)
    hash.delete(resource_class)
  end

  # @return array of strings
  def self.all_states
    hash.values.uniq.map { |klass| klass.new(nil).valid_states }.flatten.uniq
  end

  # @return array of strings
  def self.public_read_states
    hash.values.uniq.map(&:public_read_states).flatten.uniq
  end
end
