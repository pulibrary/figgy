# frozen_string_literal: true
class InstrumentedStorageAdapter
  attr_reader :storage_adapter, :tracer
  def initialize(storage_adapter:, tracer:)
    @storage_adapter = storage_adapter
    @tracer = tracer
  end

  delegate :path_generator, to: :storage_adapter

  def upload(file:, original_filename:, resource: nil, **extra_args)
    trace("valkyrie.storage.upload") do |span|
      span.set_tag("param.original_filename", original_filename)
      span.set_tag("param.resource", resource.try(:id).to_s)
      storage_adapter.upload(file: file, original_filename: original_filename, resource: resource, **extra_args)
    end
  end

  def handles?(id:)
    trace("valkyrie.storage.handles?") do |span|
      span.set_tag("param.id", id.to_s)
      storage_adapter.handles?(id: id)
    end
  end

  def find_by(id:)
    trace("valkyrie.storage.find_by") do |span|
      span.set_tag("param.id", id.to_s)
      storage_adapter.find_by(id: id)
    end
  end

  def delete(id:)
    trace("valkyrie.storage.delete") do |span|
      span.set_tag("param.id", id.to_s)
      storage_adapter.delete(id: id)
    end
  end

  def for(bag_id:)
    self.class.new(storage_adapter: storage_adapter.for(bag_id: bag_id), tracer: tracer)
  end

  def trace(resource)
    tracer.trace(span_name) do |span|
      span.service = "valkyrie-#{storage_adapter.class}"
      span.span_type = Datadog::Ext::AppTypes::DB
      span.resource = resource
      span.set_tag("storage_adapter.inspect", storage_adapter.inspect)
      yield(span)
    end
  end

  def span_name
    "valkyrie.storage"
  end
end
