# frozen_string_literal: true
class CompositeQueryAdapter
  class_attribute :query_adapter_class
  self.query_adapter_class = QueryAdapter
  class_attribute :persistence_adapter_class
  self.persistence_adapter_class = QueryAdapter::PersistenceAdapter

  attr_reader :query_adapter, :persistence_adapter
  delegate :find_by, :all, to: :query_adapter

  def initialize(query_service:, change_set_persister:)
    @query_adapter = query_adapter_class.new(query_service: query_service)
    @persistence_adapter = persistence_adapter_class.new(change_set_persister: change_set_persister)
  end

  def find_or_create_by(**args)
    label = args.fetch(:label)
    vocabulary = args.fetch(:vocabulary, nil)
    resource = @query_adapter.find_by(label: label, vocabulary: vocabulary)
    return resource if resource
    @persistence_adapter.create(**args)
  end
end
