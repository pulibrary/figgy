# frozen_string_literal: true
class NumismaticImportJob < ApplicationJob
  def perform(file_root:, db_adapter_name: "NumismaticsImportService::SqliteAdapter", **db_options)
    db_adapter = db_adapter_name.constantize.new(db_options)
    importer = NumismaticsImportService.new(db_adapter: db_adapter, logger: logger, file_root: file_root)

    importer.ingest_places
    importer.ingest_people
    importer.ingest_references
    importer.ingest_firms
    importer.ingest_accessions
    importer.ingest_monograms
    importer.issue_numbers.each do |number|
      NumismaticIssueImportJob.perform_later(issue_number: number, file_root: file_root, **db_options)
    end
  end
end
