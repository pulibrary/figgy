# frozen_string_literal: true
class LocalFixityJob < ApplicationJob
  queue_as :super_low
  delegate :query_service, to: :metadata_adapter
  attr_reader :file_set_id, :file_object, :target_file

  def perform(file_set_id)
    @file_set_id = file_set_id
    [:original_file, :intermediate_file, :preservation_file].each do |type|
      @target_file = file_set.try(type)
      next unless target_file

      # don't run if there's no existing checksum; characterization hasn't finished
      next if old_checksum.empty?
      check_fixity
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError => error
    Valkyrie.logger.warn "#{self.class}: #{error}: Failed to find the resource #{file_set_id}"
  rescue Valkyrie::StorageAdapter::FileNotFound
    # If there's no parent, and the file is gone, this is an orphan row in the
    # database, just delete it.
    raise if Wayfinder.for(file_set).parent
    metadata_adapter.persister.delete(resource: file_set)
  end

  private

    def check_fixity
      @file_object = Valkyrie::StorageAdapter.find_by(id: target_file.file_identifiers[0])
      new_checksum = MultiChecksum.for(file_object)

      event_change_set = build_event_change_set(new_checksum)

      ChangeSetPersister.default.buffer_into_index do |buffered_change_set_persister|
        buffered_change_set_persister.save(change_set: previous_event_change_set) if previous_event
        buffered_change_set_persister.save(change_set: event_change_set)
      end
    end

    def build_event_change_set(new_checksum)
      if old_checksum.include?(new_checksum)
        build_success_change_set
      else
        Honeybadger.notify("Local fixity failure on file set #{file_set_id} at location #{file_object.id}")
        build_failure_change_set(new_checksum)
      end
    end

    def build_success_change_set
      change_set = ChangeSet.for(Event.new)
      change_set.validate(
        type: :local_fixity,
        status: "SUCCESS",
        resource_id: Valkyrie::ID.new(file_set_id),
        child_id: target_file.id,
        child_property: :file_metadata,
        current: true
      )
      change_set
    end

    def build_failure_change_set(new_checksum)
      change_set = ChangeSet.for(Event.new)
      change_set.validate(
        type: :local_fixity,
        status: "FAILURE",
        resource_id: Valkyrie::ID.new(file_set_id),
        child_id: target_file.id,
        child_property: :file_metadata,
        message: new_checksum.to_h.to_json,
        current: true
      )
      change_set
    end

    def previous_event_change_set
      return unless previous_event
      ChangeSet.for(previous_event).tap do |cs|
        cs.validate(current: false)
      end
    end

    def previous_event
      @previous_event ||= query_service.custom_queries.find_by_property(
        property: :metadata,
        value: {
          type: :local_fixity,
          resource_id: { id: file_set_id.to_s },
          child_id: { id: target_file.id.to_s },
          current: true
        },
        model: Event
      ).first
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def file_set
      @file_set ||= query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    end

    def old_checksum
      target_file.checksum
    end
end
