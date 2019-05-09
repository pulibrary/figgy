# frozen_string_literal: true

# Data access object for issues in numismatics database
class NumismaticsImportService::Issues
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids
    query = "SELECT IssueID from Issue"
    db_adapter.execute(query: query).map { |r| r["IssueID"] }
  end

  def base_query(id:)
    <<-SQL
      SELECT *,
        obv_figure.#{figure_name} AS ObverseFigureName,
        rev_figure.#{figure_name} AS ReverseFigureName,
        obv_orientation.OrientationName AS ObverseOrientationName,
        rev_orientation.OrientationName AS ReverseOrientationName,
        obv_part.PartName AS ObversePartName,
        rev_part.PartName AS ReversePartName,
        obv_symbols.SymbolName AS ObverseSymbolName,
        rev_symbols.SymbolName AS ReverseSymbolName
      FROM Issue
      LEFT OUTER JOIN Denomination ON Issue.DenominationID = Denomination.DenominationID
      LEFT OUTER JOIN Era ON Issue.EraID =  Era.EraID
      LEFT OUTER JOIN Metal ON Issue.MetalID = Metal.MetalID
      LEFT OUTER JOIN Objects ON Issue.ObjectID = Objects.ObjectID
      LEFT OUTER JOIN Figure obv_figure On Issue.ObvFigureID = obv_figure.FigureID
      LEFT OUTER JOIN Figure rev_figure On Issue.RevFigureID = rev_figure.FigureID
      LEFT OUTER JOIN Orientation obv_orientation ON Issue.ObvOrientationID = obv_orientation.OrientationID
      LEFT OUTER JOIN Orientation rev_orientation ON Issue.RevOrientationID = rev_orientation.OrientationID
      LEFT OUTER JOIN Part obv_part ON Issue.ObvPartID = obv_part.PartID
      LEFT OUTER JOIN Part rev_part ON Issue.RevPartID = rev_part.PartID
      LEFT OUTER JOIN Symbols obv_symbols ON Issue.ObvSymbolID = obv_symbols.SymbolID
      LEFT OUTER JOIN Symbols rev_symbols ON Issue.RevSymbolID = rev_symbols.SymbolID
      WHERE IssueID = '#{id}'
   SQL
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def base_attributes(id:)
    record = db_adapter.execute(query: base_query(id: id)).first

    OpenStruct.new(
      issue_number: id,
      color: record["Color"],
      ce1: record["CE1"].to_s,
      ce2: record["CE2"].to_s,
      denomination: record["Denomination name"],
      edge: record["Edge"],
      era: record["EraName"],
      master_id: master_id(record), # map from master id to valkyrie id in importer
      metal: record["MetalName"],
      numismatic_place_id: record["PlaceID"].to_s, # map from place id to valkyrie id in importer
      object_date: record["DateObj"],
      object_type: record["ObjectType"],
      obverse_figure: record["ObverseFigureName"],
      obverse_figure_description: record["ObvFigureDescription"],
      obverse_figure_relationship: record["ObvFigureRelationship"],
      obverse_legend: record["ObvLeg"],
      obverse_orientation: record["ObverseOrientationName"],
      obverse_part: record["ObversePartName"],
      obverse_symbol: record["ObverseSymbolName"],
      reverse_figure: record["ReverseFigureName"],
      reverse_figure_description: record["RevFigureDescription"],
      reverse_figure_relationship: record["RevFigureRelationship"],
      reverse_legend: record["RevLeg"],
      reverse_orientation: record["ReverseOrientationName"],
      reverse_part: record["ReversePartName"],
      reverse_symbol: record["ReverseSymbolName"],
      ruler_id: ruler_id(record), # map from ruler id to valkyrie id in importer
      series: record["Series"],
      shape: record["Shape"],
      workshop: record["Workshop"]
    )
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def figure_name
    case db_adapter
    when NumismaticsImportService::SqliteAdapter
      "`Figure Name`"
    else
      "[Figure Name]"
    end
  end

  def master_id(record)
    old_id = record["MasterID"]
    return nil unless old_id
    "person-#{old_id}"
  end

  def ruler_id(record)
    old_id = record["RulerID"]
    return nil unless old_id
    "ruler-#{old_id}"
  end
end
