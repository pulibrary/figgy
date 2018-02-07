# frozen_string_literal: true
class CreateFixityCheckJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # Create a FixityCheck using the data found on the fileset object.
  # Intended for use when characterization has *just* been run.
  # Repeat: no checksums are created / compared in this job.
  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    file_id = file_set.original_file.file_identifiers.first

    # Make sure there's not already a fixity check with this file_id
    file_id_matches = query_service.custom_queries.find_by_string_property(property: :file_id, value: file_id).
      select{ |obj| obj.class == FixityCheck }.count
    return if file_id_matches > 0

    fixity_check = FixityCheck.new(
      file_set_id: file_set_id.to_s,
      file_id: file_id.to_s,
      expected_checksum: file_set.original_file.checksum,
      actual_checksum: file_set.original_file.checksum,
      success: 1,
      last_success_date: [Time.zone.now]
    )
    change_set_persister = PlumChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter, characterize: false)
    change_set_persister.save(change_set: FixityCheckChangeSet.new(fixity_check))
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:postgres)
  end

  # Won't be used but required for the change set persister
  def storage_adapter
    Valkyrie::StorageAdapter.find(:disk)
  end
end
