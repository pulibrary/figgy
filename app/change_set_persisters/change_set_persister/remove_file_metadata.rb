# frozen_string_literal: true
class ChangeSetPersister
  class RemoveFileMetadata
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return if change_set.try(:delete_file_metadata_ids).blank?
      new_file_metadata = change_set.file_metadata.select do |metadata|
        !change_set.delete_file_metadata_ids.include?(metadata.id)
      end
      change_set.deleted_file_identifiers = (change_set.file_metadata - new_file_metadata).flat_map(&:file_identifiers)
      change_set.validate(file_metadata: new_file_metadata)
    end
  end
end
