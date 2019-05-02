# frozen_string_literal: true

# Data access object for accessions in numismatics database
class NumismaticsImportService::AccessionCitations
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT AccessionRefID from AccessionRefs WHERE #{column} = '#{value}'"
            else
              "SELECT AccessionRefID from AccessionRefs"
            end
    db_adapter.execute(query: query).map { |r| r["AccessionRefID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *
      FROM AccessionRefs
      WHERE AccessionRefID = '#{id}'
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

  def accession_query(accession_id:)
    <<-SQL
      SELECT *
      FROM AccessionRefs
      WHERE AccessionID = '#{accession_id}'
    SQL
  end

  def attributes_by_accession(accession_id:)
    records = db_adapter.execute(query: accession_query(accession_id: accession_id))

    records.map do |record|
      OpenStruct.new(
        part: record["Part"],
        numismatic_reference_id: record["RefID"].to_s,
        number: record["Number"]
      )
    end
  end
end
