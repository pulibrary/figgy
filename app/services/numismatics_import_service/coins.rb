# frozen_string_literal: true

# Data access object for coins in numismatics database
class NumismaticsImportService::Coins
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = "SELECT CoinID from Coins WHERE #{column} = '#{value}'"
    db_adapter.execute(query: query).map { |r| r["CoinID"] }
  end

  # rubocop:disable Metrics/MethodLength
  def base_attributes(id:)
    record = db_adapter.execute(query: "SELECT * FROM Coins WHERE CoinID = '#{id}'").first

    OpenStruct.new(
      coin_number: id,
      number_in_accession: record["AccessionNumber"],
      numismatic_accession_id: record["AccessionID"].to_s,
      analysis: record["Analysis"],
      counter_stamp: record["CounterStamp"],
      die_axis: record["Axis"],
      find_date: record["FindDate"],
      find_description: record["FindDesc"],
      find_feature: record["FindFeature"],
      find_locus: record["FindLocus"],
      find_number: record["FindNumber"],
      find_place_id: record["FindPlaceID"].to_s, # map from place id to valkyrie id in importer
      public_note: record["OtherInfo"],
      private_note: record["PrivateInfo"],
      size: record["Size"],
      technique: record["Technique"],
      weight: record["Weight"]
    )
  end
  # rubocop:enable Metrics/MethodLength
end
