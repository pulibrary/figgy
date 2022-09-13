# frozen_string_literal: true
class BulkUpdateJob < ApplicationJob
  # rubocop:disable Lint/NonLocalExitFromIterator
  def perform(ids:, email:, args:, time:, search_params:)
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      ids.each do |id|
        resource = query_service.find_by(id: id)
        change_set = ChangeSet.for(resource)
        change_set.validate(build_attributes(resource, args))
        next unless change_set.changed?
        unless change_set.valid?
          BulkUpdateMailer.with(email: email, ids: ids, resource_id: id, time: time, search_params: search_params).update_status.deliver_now
          return
        end
        buffered_change_set_persister.save(change_set: change_set)
      end
    end
    BulkUpdateMailer.with(email: email, ids: ids, time: time, search_params: search_params).update_status.deliver_now
  end
  # rubocop:enable Lint/NonLocalExitFromIterator

  # Fields that can be bulk-edited
  def self.supported_attributes
    [
      :ocr_language,
      :refresh_remote_metadata,
      :rights_statement,
      :visibility,
      :append_collection_ids
    ]
  end

  private

    def build_attributes(resource, args)
      {}.tap do |attrs|
        attrs[:state] = "complete" if args[:mark_complete] && !deny_states.include?(resource.state.first)
        BulkUpdateJob.supported_attributes.each do |key|
          attrs[key] = args[key] if args[key]
        end
      end
    end

    def deny_states
      [
        "complete",
        "takedown"
      ]
    end

    def query_service
      metadata_adapter.query_service
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def storage_adapter
      Valkyrie::StorageAdapter.find(:disk_via_copy)
    end

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: storage_adapter
      )
    end
end
