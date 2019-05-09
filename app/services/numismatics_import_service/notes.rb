# frozen_string_literal: true

# Data access object for notes in numismatics database
class NumismaticsImportService::Notes
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def issue_query(issue_id:)
    <<-SQL
      SELECT *
      FROM IssueNotes
      LEFT OUTER JOIN NoteTypes ON NoteTypes.NoteTypeID = IssueNotes.NoteTypeID
      WHERE IssueID = '#{issue_id}'
    SQL
  end

  def attributes_by_issue(issue_id:)
    records = db_adapter.execute(query: issue_query(issue_id: issue_id))

    records.map do |record|
      OpenStruct.new(
        note: record["Note"],
        type: record["NoteType"]
      )
    end
  end
end
