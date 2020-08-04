# frozen_string_literal: true

module CDL
  class PDFIngestJob < ApplicationJob
    queue_as :high
    def perform(file_name:)
      file_path = Pathname.new(Figgy.config["cdl_in_path"]).join(file_name)
      # Open the file so it'll error if it doesn't exist.
      file = File.open(file_path)
      # Use IngestableFile to decorate the necessary methods to ingest via
      # FileAppender. copyable: true makes it "mv" instead of creating a
      # duplicate file.
      ingestable_file = IngestableFile.new(file_path: file.path, mime_type: "application/pdf", original_filename: file_path.basename, copyable: true)
      source_metadata_identifier = file_path.basename(".*").to_s
      change_set = CDL::ResourceChangeSet.new(ScannedResource.new)
      change_set.validate(files: [ingestable_file], source_metadata_identifier: source_metadata_identifier, depositor: "cdl_auto_ingest")
      change_set_persister.save(change_set: change_set)
    end

    def change_set_persister
      ScannedResourcesController.change_set_persister
    end
  end
end
