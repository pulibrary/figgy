# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::Provenances
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT ProvenanceID from Provenance WHERE #{column} = '#{value}'"
            else
              "SELECT ProvenanceID from Provenance"
            end
    db_adapter.execute(query: query).map { |r| r["ProvenanceID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM Provenance
      WHERE ProvenanceID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      firm_id: record["FirmID"],
      person_id: record["PersonID"],
      date: record["Dates"],
      note: record["Note"]
    )
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
