# frozen_string_literal: true
class BenchmarkingMetadataAdapter
  attr_reader :metadata_adapter
  delegate :resource_factory, to: :metadata_adapter
  def initialize(metadata_adapter)
    @metadata_adapter = metadata_adapter
  end

  def persister
    @persister ||= Persister.new(metadata_adapter.persister)
  end

  def query_service
    @query_service ||= QueryService.new(metadata_adapter.query_service)
  end

  class Persister
    include ActiveSupport::Benchmarkable
    attr_reader :persister
    def initialize(persister)
      @persister = persister
    end

    def save(resource:)
      run_benchmark("save: #{resource}") do
        persister.save(resource: resource)
      end
    end

    def save_all(resources:)
      run_benchmark("save_all:") do
        persister.save_all(resources: resources)
      end
    end

    def delete(resource:)
      run_benchmark("delete: #{resource}") do
        persister.delete(resource: resource)
      end
    end

    def wipe!
      run_benchmark("wipe!") do
        persister.wipe!
      end
    end

    def run_benchmark(message)
      benchmark("[#{persister}] #{message}", level: log_level) do
        yield
      end
    end

    def log_level
      :debug
    end

    def logger
      Valkyrie.logger
    end
  end

  class QueryService
    include ActiveSupport::Benchmarkable
    attr_reader :query_service
    def initialize(query_service)
      @query_service = query_service
    end

    def find_by(id:)
      run_benchmark("find_by: #{id}") do
        query_service.find_by(id: id)
      end
    end

    def find_all
      run_benchmark("find_all") do
        query_service.find_all
      end
    end

    delegate :custom_queries, to: :query_service

    def find_all_of_model(model:)
      run_benchmark("find_all_of_model: #{model}") do
        query_service.find_all_of_model(model: model)
      end
    end

    def find_parents(resource:)
      run_benchmark("find_parents: #{resource}") do
        query_service.find_parents(resource: resource)
      end
    end

    def find_inverse_references_by(resource:, property:)
      run_benchmark("find_inverse_references_by: #{resource}, #{property}") do
        query_service.find_inverse_references_by(resource: resource, property: property)
      end
    end

    def find_references_by(resource:, property:)
      run_benchmark("find_references_by: #{resource}, #{property}") do
        query_service.find_references_by(resource: resource, property: property)
      end
    end

    def find_members(resource:, model: nil)
      run_benchmark("find_members: #{resource}, #{model}") do
        query_service.find_members(resource: resource, model: model)
      end
    end

    def logger
      Valkyrie.logger
    end

    def run_benchmark(message)
      benchmark("[#{query_service}] #{message}", level: log_level) do
        yield
      end
    end

    def log_level
      :debug
    end
  end
end
