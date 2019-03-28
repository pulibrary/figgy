# frozen_string_literal: true

class NumismaticsImportService::Issues
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT IssueID from Issue WHERE #{column} = '#{value}'"
            else
              "SELECT IssueID from Issue"
            end
    db_adapter.execute(query: query).map { |r| r["IssueID"] }
  end
end
