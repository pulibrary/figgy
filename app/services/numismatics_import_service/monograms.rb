# frozen_string_literal: true

# Data access object for monograms in numismatics database
class NumismaticsImportService::Monograms
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT ImagesID from Images WHERE #{column} = '#{value}'"
            else
              "SELECT ImagesID from Images"
            end
    db_adapter.execute(query: query).map { |r| r["ImagesID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *, min(ImagesID), CAST(Filename AS BLOB) as f
      FROM Images
      WHERE ImagesID = '#{id}'
      GROUP BY f
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      filename: record["Filename"],
      title: record["Description"],
      replaces: record["ImagesID"].to_s
    )
  end
end
