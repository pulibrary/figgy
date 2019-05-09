# frozen_string_literal: true

# Data access object for coin citations in numismatics database
class NumismaticsImportService::CoinCitations
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def coin_query(coin_id:)
    <<-SQL
      SELECT *
      FROM CoinRefs
      WHERE CoinID = '#{coin_id}'
    SQL
  end

  def attributes_by_coin(coin_id:)
    records = db_adapter.execute(query: coin_query(coin_id: coin_id))

    records.map do |record|
      OpenStruct.new(
        part: record["Part"],
        numismatic_reference_id: record["RefID"].to_s,
        number: record["Number"]
      )
    end
  end
end
