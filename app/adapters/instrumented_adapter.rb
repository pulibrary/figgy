# frozen_string_literal: true

# Class modeling an adapter supporting service monitoring (e. g. Datadog)
# Provides an interface for Gems such as the Ruby Application Performance Management (APM) Tracer
# @see https://docs.datadoghq.com/tracing/setup/ruby/
class InstrumentedAdapter < SimpleDelegator
  attr_reader :metadata_adapter, :tracer
  delegate :query_service, :persister, :is_a?, :kind_of?, to: :metadata_adapter

  # Constructor
  # @param metadata_adapter [Valkyrie::Persistence::Postgres::MetadataAdapter, Valkyrie::Persistence::Memory::MetadataAdapter, Valkyrie::Persistence::Solr::MetadataAdapter, Bagit::MetadataAdapter]
  # @param tracer [Datadog::Tracer]
  def initialize(metadata_adapter:, tracer:)
    super(metadata_adapter)
    @metadata_adapter = metadata_adapter
    @tracer = tracer
  end

  # Access the persister
  # @return [InstrumentedPersister]
  def persister
    @persister ||= InstrumentedPersister.new(persister: metadata_adapter.persister, instrumented_adapter: self)
  end

  # Access the query service
  # @return [InstrumentedQueryService]
  def query_service
    @query_service ||= InstrumentedQueryService.new(query_service: metadata_adapter.query_service, instrumented_adapter: self)
  end

  # Class modeling a Rails Service Object supporting service monitoring (e. g. Datadog)
  # Provides an interface for Gems such as the Ruby Application Performance Management (APM) Tracer
  # (see SimpleDelegator)
  # @see https://docs.datadoghq.com/tracing/setup/ruby/
  class InstrumentedService < SimpleDelegator
    attr_reader :instrumented_adapter
    delegate :metadata_adapter, to: :instrumented_adapter
    delegate :tracer, to: :instrumented_adapter

    # Uses the Datadog APM agent to provide trace information
    # @see https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#manual-instrumentation
    # @param resource [String] Name of the resource or action being operated on
    def trace(resource, _resource_describer = nil)
      tracer.trace(span_name) do |span|
        span.service = "valkyrie-#{metadata_adapter.class}"
        span.span_type = Datadog::Ext::AppTypes::DB
        span.resource = resource
        yield(span)
      end
    end

    # Generates the APM name for the operation being performed
    # @return [String]
    def span_name
      "valkyrie.persist"
    end
  end

  # Class wrapping a ChangeSetPersister supporting service monitoring (e. g. Datadog)
  # Provides an interface for Gems such as the Ruby Application Performance Management (APM) Tracer
  class InstrumentedPersister < InstrumentedService
    # Constructor
    # (see SimpleDelegator)
    # @param persister [ChangeSetPersister] persister for ChangeSets
    # @param instrumented_adapter [InstrumentedAdapter] adapter for logging APM
    def initialize(persister:, instrumented_adapter:)
      @instrumented_adapter = instrumented_adapter
      super(persister)
    end

    # Traces "save" operations delegated to the ChangeSetPersister
    # @param resource [Valkyrie::Resource] resource being persisted
    def save(resource:, external_resource: false)
      trace("valkyrie.save") do |span|
        __getobj__.save(resource: resource, external_resource: external_resource).tap do |output|
          span.set_tag("param.resource", output.try(:id).to_s)
        end
      end
    end

    # Traces "deleted" operations delegated to the ChangeSetPersister
    # @param resource [Valkyrie::Resource] resource being deleted
    def delete(resource:)
      trace("valkyrie.delete") do |span|
        span.set_tag("param.resource", resource.id.to_s)
        __getobj__.delete(resource: resource)
      end
    end

    # Traces "save_all" operations delegated to the ChangeSetPersister
    # @param resources [Array<Valkyrie::Resource>] resources being saved
    def save_all(resources:)
      trace("valkyrie.save_all") do |span|
        __getobj__.save_all(resources: resources).tap do |output|
          if output.is_a?(Array)
            span.set_tag("param.resources", output.map { |x| x.id.to_s })
          end
        end
      end
    end
  end

  # Class wrapping a QueryService supporting service monitoring (e. g. Datadog)
  # Provides an interface for Gems such as the Ruby Application Performance Management (APM) Tracer
  class InstrumentedQueryService < InstrumentedService
    # Constructor
    # (see SimpleDelegator)
    # @param query_service [Valkyrie::Persistence::Postgres::QueryService, Valkyrie::Persistence::Memory::QueryService, Valkyrie::Persistence::Solr::QueryService, Bagit::QueryService]
    # @param instrumented_adapter [InstrumentedAdapter] adapter for logging APM
    def initialize(query_service:, instrumented_adapter:)
      @instrumented_adapter = instrumented_adapter
      super(query_service)
    end

    # Traces "find_by" operations delegated to the QueryService
    # @param resource [Valkyrie::ID] ID for the resource being retrieved
    def find_by(id:)
      trace("valkyrie.find_by_id") do |span|
        span.set_tag("param.id", id.to_s)
        __getobj__.find_by(id: id)
      end
    end

    # Traces "find_many_by_ids" operations delegated to the QueryService
    # @param resource [Array<Valkyrie::ID>] IDs for the resources being retrieved
    def find_many_by_ids(ids:)
      trace("valkyrie.find_many_by_ids") do |span|
        span.set_tag("param.ids", ids.map(&:to_s))
        __getobj__.find_many_by_ids(ids: ids)
      end
    end

    # Traces "find_all" operations delegated to the QueryService
    def find_all
      trace("valkyrie.find_all") do
        __getobj__.find_all
      end
    end

    # Traces "find_all_of_model" operations delegated to the QueryService
    # @param model [Class] Class for the data model of the queried resources
    def find_all_of_model(model:)
      trace("valkyrie.find_all_of_model") do |span|
        span.set_tag("param.model", model.to_s)
        __getobj__.find_all_of_model(model: model)
      end
    end

    # Traces "find_members" operations delegated to the QueryService
    # @param resource [Valkyrie::Resource] resource for which members are being queried
    # @param model [Class] Class for the data model of the queried resources
    def find_members(resource:, model: nil)
      trace("valkyrie.find_members") do |span|
        span.set_tag("param.model", model.to_s)
        span.set_tag("param.resource", resource.id.to_s)
        __getobj__.find_members(resource: resource, model: model)
      end
    end

    # Traces "find_parents" operations delegated to the QueryService
    # @param resource [Valkyrie::Resource] resource for which parents are being queried
    def find_parents(resource:)
      trace("valkyrie.find_parents") do |span|
        span.set_tag("param.resource", resource.id.to_s)
        __getobj__.find_parents(resource: resource)
      end
    end

    # Traces "find_references_by" operations delegated to the QueryService
    # @param resource [Valkyrie::Resource] resource for which referenced resources are being queried
    # @param property [Symbol] the resource property for the relation
    def find_references_by(resource:, property:, model: nil)
      trace("valkyrie.find_references_by") do |span|
        span.set_tag("param.resource", resource.id.to_s)
        span.set_tag("param.property", property.to_s)
        __getobj__.find_references_by(resource: resource, property: property, model: model)
      end
    end

    # Traces "find_inverse_references_by" operations delegated to the QueryService
    # @param resource [Valkyrie::Resource] resource to which resources referencing are being queried
    # @param property [Symbol] the resource property for the relation
    def find_inverse_references_by(resource: nil, id: nil, model: nil, property:)
      trace("valkyrie.find_inverse_references_by") do |span|
        span.set_tag("param.resource", resource.id.to_s) if resource
        span.set_tag("param.id", id.to_s) if id
        span.set_tag("param.property", property.to_s)
        __getobj__.find_inverse_references_by(resource: resource, id: id, property: property, model: model)
      end
    end

    def find_by_alternate_identifier(alternate_identifier:)
      trace("valkyrie.find_by_alternate_identifier") do |span|
        span.set_tag("param.alternate_identifier", alternate_identifier.to_s)
        __getobj__.find_by_alternate_identifier(alternate_identifier: alternate_identifier)
      end
    end

    def count_all_of_model(model:)
      trace("valkyrie.count_all_of_model") do |span|
        span.set_tag("param.model", model.to_s)
        __getobj__.count_all_of_model(model: model)
      end
    end

    # Generates the APM name for the operation being performed
    # @return [String]
    def span_name
      "valkyrie.query"
    end
  end
end
