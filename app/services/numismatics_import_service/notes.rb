# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::Notes
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT IssueNoteID from IssueNotes WHERE #{column} = '#{value}'"
            else
              "SELECT IssueNoteID from IssueNotes"
            end
    db_adapter.execute(query: query).map { |r| r["IssueNoteID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM IssueNotes
      LEFT OUTER JOIN NoteTypes ON NoteTypes.NoteTypeID = IssueNotes.NoteTypeID
      WHERE IssueNoteID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      note: record["Note"],
      type: record["NoteType"]
    )
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
