# frozen_string_literal: true

# Checks every resource in the database. If it should be preserved, then checks
# that all its files and its metadata are preserved and have the correct
# MD5 checksums.
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
    binding.pry
    query_service.find_all.each do |resource|
      # Should it be preserved?
      #   - ChangeSet.for(resource).preserve? == true
      # Is it preserved?
      #   - code that does this:
      #
      # Is the checksum correct?
      next unless ChangeSet.for(resource).preserve?
      begin
        po = Wayfinder.for(resource).preservation_object
        next unless po
      rescue Valkyrie::Persistence::ObjectNotFoundError
        failures << resource
      end
    end
    failures
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
