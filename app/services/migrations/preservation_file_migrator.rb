# frozen_string_literal: true

module Migrations
  class PreservationFileMigrator
    def self.call
      new.run
    end

    def run
      preservation_file_sets.each do |fs|
        fs.preservation_file.use = Valkyrie::Vocab::PCDMUse.PreservationFile
        change_set = ChangeSet.for(fs)
        change_set_persister.save(change_set: change_set)
      end
    end

    private

      def preservation_file_sets
        query_service.custom_queries.find_by_property(model: FileSet, property: :file_metadata, value: { use: [Valkyrie::Vocab::PCDMUse.PreservationMasterFile] }, lazy: true)
      end

      def query_service
        change_set_persister.query_service
      end

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end
  end
end
