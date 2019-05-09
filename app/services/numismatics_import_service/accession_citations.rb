# frozen_string_literal: true

# Data access object for accession citations in numismatics database
class NumismaticsImportService::AccessionCitations
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
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
