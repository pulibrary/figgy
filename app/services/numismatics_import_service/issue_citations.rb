
# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::IssueCitations
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT IssueRefID from IssueRefs WHERE #{column} = '#{value}'"
            else
              "SELECT IssueRefID from IssueRefs"
            end
    db_adapter.execute(query: query).map { |r| r["IssueRefID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM IssueRefs
      WHERE IssueRefID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      part: record["Part"],
      numismatic_reference_id: record["RefID"],
      number: record["Number"]
    )
  end

  def issue_query(issue_id:)
    <<-SQL
      SELECT *
      FROM IssueRefs
      WHERE IssueID = '#{issue_id}'
    SQL
  end

  def attributes_by_issue(issue_id:)
    records = db_adapter.execute(query: issue_query(issue_id: issue_id))

    records.map do |record|
      OpenStruct.new(
        part: record["Part"],
        numismatic_reference_id: record["RefID"].to_s,
        number: record["Number"]
      )
    end
  end
end
