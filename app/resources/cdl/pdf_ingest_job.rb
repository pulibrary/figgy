# frozen_string_literal: true

module CDL
  class PDFIngestJob < ApplicationJob
    queue_as :high
    def perform(file_name:)
      file_path = Pathname.new(Figgy.config["cdl_in_path"]).join("ingesting", file_name)
      # Open the file so it'll error if it doesn't exist.
      file = File.open(file_path)
      # Use IngestableFile to decorate the necessary methods to ingest via
      # FileAppender.
      ingestable_file = IngestableFile.new(file_path: file.path, mime_type: "application/pdf", original_filename: file_path.basename)
      source_metadata_identifier = file_path.basename(".*").to_s
      change_set = CDL::ResourceChangeSet.new(ScannedResource.new)
      change_set.validate(files: [ingestable_file], source_metadata_identifier: source_metadata_identifier, depositor: "cdl_auto_ingest", member_of_collection_ids: [collection_id].compact)
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        output = buffered_change_set_persister.save(change_set: change_set)
        raise "No PDF Found: #{file_name}" if output.member_ids.empty?
      end
      FileUtils.rm(file_path)
    end

    def change_set_persister
      ChangeSetPersister.default
    end

    def collection_id
      change_set_persister.query_service.custom_queries.find_by_property(property: :slug, value: "cdl", model: Collection).first.id
    end
  end
end
