# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::NumismaticAttributes
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT IssueAttributeID from IssueAttributes WHERE #{column} = '#{value}'"
            else
              "SELECT IssueAttributeID from IssueAttributes"
            end
    db_adapter.execute(query: query).map { |r| r["IssueAttributeID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM IssueAttributes
      LEFT OUTER JOIN Attributes ON Attributes.AttributeID = IssueAttributes.AttributeID
      WHERE IssueAttributeID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      description: record["Description"],
      name: record["AttributeName"]
    )
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
