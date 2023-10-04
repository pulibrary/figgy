# frozen_string_literal: true

# Checks every resource in the database. If it should be preserved, then checks
# that all its files and its metadata are preserved and have the correct
# MD5 checksums.
# Future use case: We'll get this to where it returns nothing. If down the road
# it returns something again, we'll want more details about what / why it's
# failing.
class PreservationStatusReporter
  attr_reader :since
  def initialize(since: nil)
    @since = since
  end

  # @return [Array<Valkyrie::Resource>]
  # Takes a block which will yield before every resource it's checking, to allow
  # for a progress bar or other similar counting.
  def cloud_audit_failures(&block)
    @cloud_audit_failures ||= run_cloud_audit(&block)
  end

  def audited_resource_count
    query_service.custom_queries.count_all_except_models(except_models: unpreserved_models)
  end

  def records_per_group
    100
  end

  def parallel_threads
    10
  end

  # @return [Array<Valkyrie::Resource>] a lazy enumerator
  def run_cloud_audit
    query_service.custom_queries.memory_efficient_all(except_models: unpreserved_models, order: true, since: since).each_slice(records_per_group).lazily.in_threads(parallel_threads) do |resources|
      resources.select do |resource|
        yield if block_given?
        # if it should't preserve we don't care about it
        next unless ChangeSet.for(resource).preserve?
        # if it should preserve and there's no preservation object, it's a failure
        preservation_object = Wayfinder.for(resource).preservation_object
        if preservation_object.nil?
          true
          # if preservation object doesn't have a metadata node
        elsif preservation_object.metadata_node.nil?
          true
        elsif incorrectly_preserved?(resource, preservation_object)
          true
        else
          false
        end
      end
    end.flatten
  end

  # Preservation object is missing a binary node or the checksums don't match.
  def incorrectly_preserved?(resource, preservation_object)
    checkers = Preserver::PreservationChecker.for(resource: resource, preservation_object: preservation_object)
    checkers.any? { |x| !x.preserved? || !x.preservation_file_exists? || !x.preserved_file_checksums_match? }
  end

  def unpreserved_models
    [
      DeletionMarker,
      Event,
      PreservationObject,
      CDL::ResourceChargeList
    ]
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
