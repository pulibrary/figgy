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

      checkers = Preserver::PreservationChecker.for(resource: resource, preservation_object: po)
      # PO is missing a binary node or the checksums don't match.
      if checkers.any? { |x| !x.preserved? || !x.preservation_file_exists? || !x.preserved_file_checksums_match? }
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
