# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::CoinCitations
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT CoinRefID from CoinRefs WHERE #{column} = '#{value}'"
            else
              "SELECT CoinRefID from CoinRefs"
            end
    db_adapter.execute(query: query).map { |r| r["CoinRefID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM CoinRefs
      WHERE CoinRefID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      part: record["Part"],
      numismatic_reference_id: record["RefID"],
      number: record["Number"]
    )
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
