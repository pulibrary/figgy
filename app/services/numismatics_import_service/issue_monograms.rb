# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::IssueMonograms
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids_by_issue(issue_id:)
    db_adapter.execute(query: base_query(issue_id: issue_id)).map { |r| r["ImagesID"] }
  end

  def base_query(issue_id:)
    <<-SQL
      SELECT Images.ImagesID, min(ImagesID), Coins.IssueID, CAST(Filename AS BLOB) as f
      FROM Images
      LEFT OUTER JOIN Coins On Coins.CoinID = Images.CoinID
      WHERE IssueID = '#{issue_id}'
      GROUP BY f, IssueID
    SQL
  end
end
