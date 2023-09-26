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
      # Should it be preserved?
      #   - ChangeSet.for(resource).preserve? == true
      # Is it preserved?
      #   - code that does this:
      #
      # Is the checksum correct?
      # if it doesn't preserve we don't care about it
      next unless ChangeSet.for(resource).preserve?
      # if it should preserve and there's no preservation object, it's a failure
      po = Wayfinder.for(resource).preservation_object
      binary_composite = Preserver::BinaryNodeComposite.new(resource: resource, preservation_object: po)
      if po.nil?
        failures << resource
        next
      # PO is missing a binary node or the checksums don't match.
      elsif binary_composite.any? { |x| !x.preserved? }
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
