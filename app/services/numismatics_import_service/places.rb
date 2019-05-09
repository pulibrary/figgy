# frozen_string_literal: true

# Data access object for places in numismatics database
class NumismaticsImportService::Places
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids
    query = "SELECT PlaceID from Place"
    db_adapter.execute(query: query).map { |r| r["PlaceID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT Place.PlaceID, Place.City, State.StateName, Region.RegionName
      FROM Place
      LEFT OUTER JOIN State ON Place.StateID = State.StateID
      LEFT OUTER JOIN Region ON Place.RegionID = Region.RegionID
      WHERE PlaceID = '#{id}'
    SQL
  end

  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      city: record["City"],
      geo_state: record["StateName"],
      region: record["RegionName"],
      replaces: record["PlaceID"].to_s
    )
  end
end
