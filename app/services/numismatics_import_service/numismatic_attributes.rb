# frozen_string_literal: true

# Data access object for numismatic attributes in numismatics database
class NumismaticsImportService::NumismaticAttributes
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def issue_query(issue_id:, side:)
    <<-SQL
      SELECT *
      FROM IssueAttributes
      LEFT OUTER JOIN Attributes ON Attributes.AttributeID = IssueAttributes.AttributeID
      WHERE IssueID = '#{issue_id}' AND Side = '#{side}'
    SQL
  end

  def attributes_by_issue(issue_id:, side:)
    records = db_adapter.execute(query: issue_query(issue_id: issue_id, side: side))

    records.map do |record|
      OpenStruct.new(
        description: record["Description"],
        name: record["AttributeName"]
      )
    end
  end
end
