# frozen_string_literal: true
class NumismaticImportJob < ApplicationJob
  def perform(issue_number:, db_adapter:, file_root:)
    logger.info "Importing numismatic issue: #{issue_number}"
    importer = NumismaticsImportService.new(db_adapter: db_adapter, logger: logger, file_root: file_root)
    importer.ingest_issue(issue_number: issue_number)
  end
end
