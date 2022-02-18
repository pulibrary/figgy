# frozen_string_literal: true

class ChangeSetPersister
  class UpdateOCR
    attr_reader :change_set_persister, :change_set

    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      # @post_save_resource = post_save_resource
    end

    def run
      return unless change_set.changed["ocr_language"] == true && change_set.ocr_language.present?
      query_service.find_members(resource: change_set.resource, model: FileSet).each do |file_set|
        ::RunOCRJob.perform_later(file_set.id.to_s)
      end
    end

    def query_service
      change_set_persister.metadata_adapter.query_service
    end
  end
end
