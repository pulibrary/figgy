# frozen_string_literal: true

# Data access object for artists in numismatics database
class NumismaticsImportService::Artists
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def issue_query(issue_id:)
    <<-SQL
      SELECT *
      FROM IssueArtist
      WHERE IssueID = '#{issue_id}'
    SQL
  end

  def attributes_by_issue(issue_id:)
    records = db_adapter.execute(query: issue_query(issue_id: issue_id))

    records.map do |record|
      OpenStruct.new(
        person_id: record["PersonID"],
        signature: record["Signature"],
        role: record["Role"],
        side: record["Side"]
      )
    end
  end
end
