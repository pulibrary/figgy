# frozen_string_literal: true

# Data access object for monograms in numismatics database
class NumismaticsImportService::Monograms
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids
    db_adapter.execute(query: ids_query).map { |r| r["ImagesID"] }
  end

  def ids_query
    case db_adapter
    when NumismaticsImportService::SqliteAdapter
      sqlite_ids_query
    else
      sql_server_ids_query
    end
  end

  def sqlite_ids_query
    <<-SQL
      SELECT *, min(ImagesID), CAST(Filename AS BLOB) as f
      FROM Images
      GROUP BY f
    SQL
  end

  def sql_server_ids_query
    <<-SQL
      SELECT Filename, MIN(ImagesID) AS ImagesID, Min(Description) AS Description
      FROM Images
      GROUP BY Filename
    SQL
  end

  def base_query(id:)
    case db_adapter
    when NumismaticsImportService::SqliteAdapter
      sqlite_base_query(id: id)
    else
      sql_server_base_query(id: id)
    end
  end

  def sqlite_base_query(id:)
    <<-SQL
      SELECT *, min(ImagesID), CAST(Filename AS BLOB) as f
      FROM Images
      WHERE ImagesID = '#{id}'
      GROUP BY f
    SQL
  end

  def sql_server_base_query(id:)
    <<-SQL
      SELECT Filename, MIN(ImagesID) AS ImagesID, Min(Description) AS Description
      FROM Images
      WHERE ImagesID = '#{id}'
      GROUP BY Filename
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
