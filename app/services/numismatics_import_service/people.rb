# frozen_string_literal: true

# Data access object for people in numismatics database
class NumismaticsImportService::People
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    db_adapter.execute(query: combined_query).map { |r| r["PersonRulerID"] }
  end

  def combined_query
    <<-SQL
      SELECT *
      FROM (SELECT #{person_concat} AS PersonRulerID,
              FirstName AS Name1,
              FamilyName AS Name2,
              NULL AS Epithet,
              NULL AS FamilyName,
              Born,
              Died,
              ClassOf,
              NULL AS YearsActiveStart,
              NULL AS YearsActiveEnd
            FROM Person
            UNION ALL
            SELECT #{ruler_concat} AS PersonRulerID,
              RulerName1 AS Name1,
              RulerName2 AS Name2,
              RulerEpithet AS Epithet,
              FamName AS FamilyName,
              NULL AS Born,
              NULL AS Died,
              NULL AS ClassOf,
              RulerDateFirst AS YearsActiveStart,
              RulerDateLast AS YearsActiveEnd
            FROM Ruler
            LEFT OUTER JOIN Family ON Family.FamID = Ruler.FamID) AS PersonRuler
    SQL
  end

  def person_concat
    case db_adapter
    when NumismaticsImportService::SqliteAdapter
      "'person-' || PersonID"
    else
      "'person-' + CAST(PersonID AS VARCHAR(16))"
    end
  end

  def ruler_concat
    case db_adapter
    when NumismaticsImportService::SqliteAdapter
      "'ruler-' || RulerID"
    else
      "'ruler-' + CAST(RulerID AS VARCHAR(16))"
    end
  end

  def base_query(id:)
    "#{combined_query} WHERE PersonRuler.PersonRulerID = '#{id}'"
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      name1: record["Name1"],
      name2: record["Name2"],
      epithet: record["Epithet"],
      family: record["FamilyName"],
      born: record["Born"]&.to_s,
      died: record["Died"]&.to_s,
      class_of: record["ClassOf"],
      years_active_start: record["YearsActiveStart"]&.to_s,
      years_active_end: record["YearsActiveEnd"]&.to_s,
      replaces: record["PersonRulerID"].to_s
    )
  end
end
