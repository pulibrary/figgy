# frozen_string_literal: true

# Data access object for issue citations in numismatics database
class NumismaticsImportService::IssueCitations
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
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
