# frozen_string_literal: true

# Checks every resource in the database. If it should be preserved, then checks
# that all its files and its metadata are preserved and have the correct
# MD5 checksums.
# Future use case: We'll get this to where it returns nothing. If down the road
# it returns something again, we'll want more details about what / why it's
# failing.
class PreservationStatusReporter
  # reporter = PreservationStatusReporter.new(progress_bar: true)
  def initialize(progress_bar: true)
    @progress_bar = progress_bar
  end

  # @return [Array<Valkyrie::Resource>]
  def cloud_audit_failures
    @cloud_audit_failures ||= run_cloud_audit
  end

  # @return [Array<Valkyrie::Resource>]
  def run_cloud_audit
    failures = []
    query_service.find_all.each do |resource|
      # if it should't preserve we don't care about it
      next unless ChangeSet.for(resource).preserve?
      # if it should preserve and there's no preservation object, it's a failure
      po = Wayfinder.for(resource).preservation_object
      if po.nil?
        failures << resource
        next
      end

      # if preservation object doesn't have a metadata node
      if po.metadata_node.nil?
        failures << resource
        next
      end
      # Stub this using
      # https://rubydoc.info/github/rspec/rspec-mocks/RSpec%2FMocks%2FExampleMethods:receive_message_chain
      # streamfile = Valkyrie::StorageAdapter.find_by(id: po.metadata_node.file_identifiers.first)
      # remote_compact_md5 = streamfile.io.file.data[:file].md5

      #  TODO: Options Options for refactors
      # preservation_object.intermediaries_for(resource)
      # resource.preservation_intermediaries_for(preservation_object)
      # resource.preservation_targets.map { |file_metadata| file_metadata.intermediary_for(preservation_object) }
      # PreservationObject.intermediaries_for(resource, preservation_object)
      # BinaryIntermediaryNode.for(resource, preservation_object) # => []
      # PreservationChecker.for(resource, preservation_object)
      binary_composite = Preserver::BinaryNodeComposite.new(resource: resource, preservation_object: po)
      # PO is missing a binary node or the checksums don't match.
      if binary_composite.any? { |x| !x.preserved? }
        failures << resource
        next
      end
    end
    failures
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
