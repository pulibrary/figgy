# frozen_string_literal: true
class NumismaticIssueImportJob < ApplicationJob
  def perform(issue_number:, collection_id:, depositor:, file_root:, db_adapter_name: "NumismaticsImportService::SqliteAdapter", **db_options)
    db_adapter = db_adapter_name.constantize.new(db_options)
    logger.info "Importing numismatic issue: #{issue_number}"
    importer = NumismaticsImportService.new(db_adapter: db_adapter, collection_id: collection_id, depositor: depositor, logger: logger, file_root: file_root)
    importer.ingest_issue(issue_number: issue_number)
  end
end
