# frozen_string_literal: true
class InstrumentedAdapter < SimpleDelegator
  attr_reader :metadata_adapter, :tracer
  delegate :query_service, :persister, :is_a?, :kind_of?, to: :metadata_adapter
  def initialize(metadata_adapter:, tracer:)
    super(metadata_adapter)
    @metadata_adapter = metadata_adapter
    @tracer = tracer
  end

  def persister
    @persister ||= InstrumentedPersister.new(persister: metadata_adapter.persister, instrumented_adapter: self)
  end

  def query_service
    @query_service ||= InstrumentedQueryService.new(query_service: metadata_adapter.query_service, instrumented_adapter: self)
  end

  class InstrumentedService < SimpleDelegator
    attr_reader :instrumented_adapter
    delegate :metadata_adapter, to: :instrumented_adapter
    delegate :tracer, to: :instrumented_adapter
    def trace(resource, _resource_describer = nil)
      tracer.trace(span_name) do |span|
        span.service = "valkyrie-#{metadata_adapter.class}"
        span.span_type = Datadog::Ext::AppTypes::DB
        output = yield(span)
        span.resource = resource
        output
      end
    end

    def span_name
      'valkyrie.persist'
    end
  end
  class InstrumentedPersister < InstrumentedService
    def initialize(persister:, instrumented_adapter:)
      @instrumented_adapter = instrumented_adapter
      super(persister)
    end

    def save(resource:)
      trace('valkyrie.save') do |span|
        __getobj__.save(resource: resource).tap do |output|
          span.set_tag('param.resource', output.id.to_s)
        end
      end
    end

    def delete(resource:)
      trace('valkyrie.delete') do |span|
        __getobj__.delete(resource: resource).tap do
          span.set_tag('param.resource', resource.id.to_s)
        end
      end
    end

    def save_all(resources:)
      trace('valkyrie.save_all') do |span|
        __getobj__.save_all(resources: resources).tap do |output|
          span.set_tag('param.resources', output.map { |x| x.id.to_s })
        end
      end
    end
  end
  class InstrumentedQueryService < InstrumentedService
    def initialize(query_service:, instrumented_adapter:)
      @instrumented_adapter = instrumented_adapter
      super(query_service)
    end

    def find_by(id:)
      trace('valkyrie.find_by_id') do |span|
        __getobj__.find_by(id: id).tap do
          span.set_tag('param.id', id.to_s)
        end
      end
    end

    def find_all
      trace('valkyrie.find_all') do
        __getobj__.find_all
      end
    end

    def find_all_of_model(model:)
      trace('valkyrie.find_all_of_model') do |span|
        __getobj__.find_all_of_model(model: model).tap do
          span.set_tag('param.model', model.to_s)
        end
      end
    end

    def find_members(resource:, model: nil)
      trace('valkyrie.find_members') do |span|
        __getobj__.find_members(resource: resource, model: model).tap do
          span.set_tag('param.model', model.to_s)
          span.set_tag('param.resource', resource.id.to_s)
        end
      end
    end

    def find_parents(resource:)
      trace('valkyrie.find_parents') do |span|
        __getobj__.find_parents(resource: resource).tap do
          span.set_tag('param.resource', resource.id.to_s)
        end
      end
    end

    def find_references_by(resource:, property:)
      trace('valkyrie.find_references_by') do |span|
        __getobj__.find_references_by(resource: resource, property: property).tap do
          span.set_tag('param.resource', resource.id.to_s)
          span.set_tag('param.property', property.to_s)
        end
      end
    end

    def find_inverse_references_by(resource:, property:)
      trace('valkyrie.find_inverse_references_by') do |span|
        __getobj__.find_inverse_references_by(resource: resource, property: property).tap do
          span.set_tag('param.resource', resource.id.to_s)
          span.set_tag('param.property', property.to_s)
        end
      end
    end

    def span_name
      'valkyrie.query'
    end
  end
end
