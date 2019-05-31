# frozen_string_literal: true
class NumismaticImportJob < ApplicationJob
  def perform(file_root:, collection_id:, depositor:, db_adapter_name: "NumismaticsImportService::SqliteAdapter", **db_options)
    db_adapter = db_adapter_name.constantize.new(db_options)
    # Use the first admin user as a depositor in the numismatic import
    depositor = Role.where(name: "admin").first.users.first.uid

    importer = NumismaticsImportService.new(db_adapter: db_adapter, collection_id: collection_id, depositor: depositor, logger: logger, file_root: file_root)

    importer.ingest_places
    importer.ingest_people
    importer.ingest_references
    importer.ingest_firms
    importer.ingest_accessions
    importer.ingest_monograms
    importer.issue_numbers.each do |number|
      NumismaticIssueImportJob.perform_later(issue_number: number, collection_id: collection_id, depositor: depositor, file_root: file_root, db_adapter_name: db_adapter_name, **db_options)
    end
  end
end
