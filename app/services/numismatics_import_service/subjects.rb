# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::Subjects
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT IssueSubjectID from SubjectTab WHERE #{column} = '#{value}'"
            else
              "SELECT IssueSubjectID from SubjectTab"
            end
    db_adapter.execute(query: query).map { |r| r["IssueSubjectID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM SubjectTab
      WHERE IssueSubjectID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      type: record["SubjectType"],
      subject: record["Subject"]
    )
  end

  def issue_query(issue_id:)
    <<-SQL
      SELECT *
      FROM SubjectTab
      WHERE IssueID = '#{issue_id}'
    SQL
  end

  def attributes_by_issue(issue_id:)
    records = db_adapter.execute(query: issue_query(issue_id: issue_id))

    records.map do |record|
      OpenStruct.new(
        type: record["SubjectType"],
        subject: record["Subject"]
      )
    end
  end
end
