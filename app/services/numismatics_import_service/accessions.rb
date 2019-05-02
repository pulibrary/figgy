# frozen_string_literal: true

# Data access object for accesions in numismatics database
class NumismaticsImportService::Accessions
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT AccessionID from Accessions WHERE #{column} = '#{value}'"
            else
              "SELECT AccessionID from Accessions"
            end
    db_adapter.execute(query: query).map { |r| r["AccessionID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM Accessions
      WHERE AccessionID = '#{id}'
    SQL
  end

  # rubocop:disable Metrics/MethodLength
  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      firm_id: record["AccFirmID"].to_s,
      person_id: record["AccPersonID"].to_s,
      numismatic_citation: record["AccRefID"],
      accession_number: record["AccessionID"].to_s,
      account: record["Account"],
      cost: record["Cost"],
      date: record["AccDate"],
      items_number: record["AccNumber"],
      note: record["Info"],
      private_note: record["PrivateInfo"],
      replaces: record["AccessionID"].to_s,
      type: record["AccType"]
    )
  end
  # rubocop:enable Metrics/MethodLength
end
