# frozen_string_literal: true
class NumismaticImportJob < ApplicationJob
  def perform(issue_number:, file_root:, db_adapter_name: "NumismaticsImportService::SqliteAdapter", **db_options)
    db_adapter = db_adapter_name.constantize.new(db_options)
    logger.info "Importing numismatic issue: #{issue_number}"
    importer = NumismaticsImportService.new(db_adapter: db_adapter, logger: logger, file_root: file_root)
    importer.ingest_issue(issue_number: issue_number)
  end
end
