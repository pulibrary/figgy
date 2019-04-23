# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::Artists
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT IssueArtistID from IssueArtist WHERE #{column} = '#{value}'"
            else
              "SELECT IssueArtistID from IssueArtist"
            end
    db_adapter.execute(query: query).map { |r| r["IssueArtistID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM IssueArtist
      WHERE IssueArtistID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      person_id: record["PersonID"],
      signature: record["Signature"],
      role: record["Role"],
      side: record["Side"]
    )
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
