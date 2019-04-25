# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::References
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT ReferenceID from #{table_name} WHERE #{column} = '#{value}'"
            else
              "SELECT ReferenceID from #{table_name}"
            end
    db_adapter.execute(query: query).map { |r| r["ReferenceID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT Refs.*, RefAuthor.PersonID
      FROM #{table_name}
      LEFT OUTER JOIN RefAuthor ON RefAuthor.ReferenceID = #{table_name}.ReferenceID
      WHERE Refs.ReferenceID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      author_id: authors(id: id),
      parent_ids: record["ParentRefID"],
      part_of_parent: record["PartOfParent"],
      pub_info: record["PubInfo"],
      short_title: record["ShortTitle"],
      title: record["Title"],
      year: record["Year"].to_s,
      replaces: record["ReferenceID"].to_s
    )
  end

  def authors(id:)
    records = db_adapter.execute(query: authors_query(id: id))
    records.map do |record|
      author_id(record)
    end
  end

  def authors_query(id:)
    <<-SQL
      SELECT PersonID
      FROM RefAuthor
      WHERE ReferenceID = '#{id}'
    SQL
  end

  def author_id(record)
    old_id = record["PersonID"]
    "person-#{old_id}"
  end

  def table_name
    db_adapter.is_a?(NumismaticsImportService::SqliteAdapter) ? "Refs" : "References"
  end
end
