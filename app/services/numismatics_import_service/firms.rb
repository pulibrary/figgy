# frozen_string_literal: true

# Data access object for firms in numismatics database
class NumismaticsImportService::Firms
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids
    query = "SELECT FirmID from Firms"
    db_adapter.execute(query: query).map { |r| r["FirmID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM Firms
      WHERE FirmID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      city: record["FirmCity"],
      name: record["FirmName"],
      replaces: record["FirmID"].to_s
    )
  end
end
