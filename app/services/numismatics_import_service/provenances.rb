# frozen_string_literal: true

# Data access object for provenances in numismatics database
class NumismaticsImportService::Provenances
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def coin_query(coin_id:)
    <<-SQL
      SELECT *
      FROM Provenance
      WHERE CoinID = '#{coin_id}'
    SQL
  end

  def attributes_by_coin(coin_id:)
    records = db_adapter.execute(query: coin_query(coin_id: coin_id))

    records.map do |record|
      OpenStruct.new(
        firm_id: record["FirmID"].to_s,
        person_id: record["PersonID"].to_s,
        date: record["Dates"],
        note: record["Note"]
      )
    end
  end
end
