# frozen_string_literal: true
class InstrumentedAdapter < SimpleDelegator
  attr_reader :metadata_adapter
  delegate :query_service, :persister, :is_a?, :kind_of?, to: :metadata_adapter
  def initialize(metadata_adapter:)
    super(metadata_adapter)
    @metadata_adapter = metadata_adapter
  end

  def persister
    @persister ||= InstrumentedPersister.new(persister: metadata_adapter.persister, instrumented_adapter: self)
  end

  def query_service
    @query_service ||= InstrumentedQueryService.new(query_service: metadata_adapter.query_service, instrumented_adapter: self)
  end

  def tracer
    @tracer ||= Datadog.tracer
  end

  class InstrumentedService < SimpleDelegator
    attr_reader :instrumented_adapter
    delegate :metadata_adapter, to: :instrumented_adapter
    delegate :tracer, to: :instrumented_adapter
    def trace(span_name, resource_describer = method(:resource_to_string))
      tracer.trace(span_name) do |span|
        span.service = "valkyrie-#{metadata_adapter.class}"
        span.span_type = Datadog::Ext::AppTypes::DB
        output = yield
        span.resource = resource_describer.call(output)
        output
      end
    end

    def resource_to_string(resources)
      Array.wrap(resources).map { |resource| "#{resource.class}<id: #{resource.id}>" }.join(", ")
    end
  end
  class InstrumentedPersister < InstrumentedService
    def initialize(persister:, instrumented_adapter:)
      @instrumented_adapter = instrumented_adapter
      super(persister)
    end

    def save(resource:)
      trace('valkyrie.save') do
        __getobj__.save(resource: resource)
      end
    end

    def delete(resource:)
      trace('valkyrie.delete', ->(_) { resource_to_string(resource) }) do
        __getobj__.delete(resource: resource)
      end
    end

    def save_all(resources:)
      trace('valkyrie.save_all') do
        __getobj__.save_all(resources: resources)
      end
    end
  end
  class InstrumentedQueryService < InstrumentedService
    def initialize(query_service:, instrumented_adapter:)
      @instrumented_adapter = instrumented_adapter
      super(query_service)
    end

    def find_by(id:)
      trace('valkyrie.find_by_id', ->(_resource) { id.to_s }) do
        __getobj__.find_by(id: id)
      end
    end

    def find_all
      trace('valkyrie.find_all', ->(_resource) {}) do
        __getobj__.find_all
      end
    end

    def find_all_of_model(model:)
      trace('valkyrie.find_all_of_model', ->(_) { model.to_s }) do
        __getobj__.find_all_of_model(model: model)
      end
    end

    def find_members(resource:, model: nil)
      trace('valkyrie.find_members', ->(_) { resource_to_string(resource) }) do
        __getobj__.find_members(resource: resource, model: model)
      end
    end

    def find_parents(resource:)
      trace('valkyrie.find_parents', ->(_) { resource_to_string(resource) }) do
        __getobj__.find_parents(resource: resource)
      end
    end

    def find_references_by(resource:, property:)
      trace('valkyrie.find_references_by', ->(_) { "#{resource_to_string(resource)} - #{property}" }) do
        __getobj__.find_references_by(resource: resource, property: property)
      end
    end

    def find_inverse_references_by(resource:, property:)
      trace('valkyrie.find_inverse_references_by', ->(_) { "#{resource_to_string(resource)} - #{property}" }) do
        __getobj__.find_inverse_references_by(resource: resource, property: property)
      end
    end
  end
end
