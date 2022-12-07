# frozen_string_literal: true
class ReprocessMetsJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter
  def perform(collection_id:)
    collection = query_service.find_by(id: collection_id)
    wayfinder = Wayfinder.for(collection)
    change_set_persister.buffer_into_index do |buffered_adapter|
      wayfinder.members.each do |member|
        member_wayfinder = Wayfinder.for(member)
        mets_fileset = member_wayfinder.file_sets.find { |x| x.mime_type.include?(mets_mime_type) }
        next unless mets_fileset
        mets_file = Valkyrie::StorageAdapter.find_by(id: mets_fileset.primary_file.file_identifiers.first)
        mets_document = METSDocument::Factory.new(mets_file.disk_path).new
        change_set = ChangeSet.for(member)
        change_set.validate(mets_document.attributes)
        buffered_adapter.save(change_set: change_set)
      end
    end
  end

  def mets_mime_type
    "application/xml; schema=mets"
  end

  def change_set_persister
    @change_set_persister ||= ChangeSetPersister.new(metadata_adapter: metadata_adapter,
                                                     storage_adapter: storage_adapter,
                                                     queue: queue_name)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def storage_adapter
    Valkyrie::StorageAdapter.find(:disk_via_copy)
  end
end
