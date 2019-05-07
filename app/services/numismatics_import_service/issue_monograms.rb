# frozen_string_literal: true

# Data access object for issue monograms in numismatics database
class NumismaticsImportService::IssueMonograms
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids_by_issue(issue_id:)
    db_adapter.execute(query: base_query(issue_id: issue_id)).map { |r| r["ImagesID"] }
  end

  def base_query(issue_id:)
    case db_adapter
    when NumismaticsImportService::SqliteAdapter
      sqlite_base_query(issue_id: issue_id)
    else
      sql_server_base_query(issue_id: issue_id)
    end
  end

  def sqlite_base_query(issue_id:)
    <<-SQL
      SELECT Images.ImagesID, min(ImagesID), Coins.IssueID, CAST(Filename AS BLOB) as f
      FROM Images
      LEFT OUTER JOIN Coins On Coins.CoinID = Images.CoinID
      WHERE IssueID = '#{issue_id}'
      GROUP BY f, IssueID
    SQL
  end

  def sql_server_base_query(issue_id:)
    <<-SQL
      SELECT Filename, MIN(ImagesID) AS ImagesID, Coins.IssueID
      FROM Images
      LEFT OUTER JOIN Coins On Coins.CoinID = Images.CoinID
      WHERE IssueID = '#{issue_id}'
      GROUP BY Filename, IssueID
    SQL
  end
end
