# frozen_string_literal: true

module Migrations
  # Re-preserve all FileSets with attached PreservationFiles.
  class PreservationFilePreserver
    def self.call
      new.run
    end

    def run
      preservation_file_sets.each do |fs|
        PreserveResourceJob.perform_later(id: fs.id.to_s, force_preservation: true)
      end
    end

    private

      def preservation_file_sets
        query_service.custom_queries.find_by_property(model: FileSet, property: :file_metadata, value: { use: [::PcdmUse::PreservationFile] }, lazy: true)
      end

      def query_service
        change_set_persister.query_service
      end

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end
  end
end
