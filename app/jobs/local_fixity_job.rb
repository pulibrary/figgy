# frozen_string_literal: true
class LocalFixityJob < ApplicationJob
  queue_as :super_low
  delegate :query_service, to: :metadata_adapter
  attr_reader :file_set_id

  def perform(file_set_id)
    @file_set_id = file_set_id
    # don't run if there's no existing checksum; characterization hasn't finished
    return if old_checksum.empty?
    new_checksum = MultiChecksum.for(file)

    event_change_set = build_event_change_set(new_checksum)
    ChangeSetPersister.default.save(change_set: event_change_set)
  rescue Valkyrie::Persistence::ObjectNotFoundError => error
    Valkyrie.logger.warn "#{self.class}: #{error}: Failed to find the resource #{file_set_id}"
  rescue Valkyrie::StorageAdapter::FileNotFound
    # If there's no parent, and the file is gone, this is an orphan row in the
    # database, just delete it.
    raise if Wayfinder.for(file_set).parent
    metadata_adapter.persister.delete(resource: file_set)
  end

  private

    def build_event_change_set(new_checksum)
      if old_checksum.include?(new_checksum)
        build_success_change_set
      else
        Honeybadger.notify("Local fixity failure on file set #{file_set_id} at location #{file.id}")
        build_failure_change_set(new_checksum)
      end
    end

    def build_success_change_set
      change_set = ChangeSet.for(Event.new)
      change_set.validate(
        type: :local_fixity,
        status: "SUCCESS",
        resource_id: file_set_id
      )
      change_set
    end

    def build_failure_change_set(new_checksum)
      change_set = ChangeSet.for(Event.new)
      change_set.validate(
        type: :local_fixity,
        status: "FAILURE",
        resource_id: file_set_id,
        message: new_checksum.to_h.to_json
      )
      change_set
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def file_set
      @file_set ||= query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    end

    def file
      @file ||= Valkyrie::StorageAdapter.find_by(id: primary_file.file_identifiers.first)
    end

    def primary_file
      file_set.primary_file
    end

    def old_checksum
      primary_file.checksum
    end
end
