# frozen_string_literal: true

class NumismaticsImportService::Issues
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def ids(column: nil, value: nil)
    query = if column
              "SELECT IssueID from Issue WHERE #{column} = '#{value}'"
            else
              "SELECT IssueID from Issue"
            end
    db_adapter.execute(query: query).map { |r| r["IssueID"] }
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def base_attributes(id:)
    record = db_adapter.execute(query: "SELECT * FROM Issue WHERE IssueID = '#{id}'").first

    OpenStruct.new(
      issue_number: id,
      artist: nil, # nested
      color: record["Color"],
      date_range: nil, # nested?
      denomination: nil, # lookup
      edge: record["Edge"],
      era: nil, # lookup
      master: nil, # nested person
      metal: nil, # lookup
      note: nil, # nested?
      place: nil, # nested
      object_date: record["DateObj"],
      object_type: nil, # lookup
      obverse_attributes: nil, # nested. attr image is not displayed
      obverse_figure: nil, # lookup
      obverse_figure_description: record["ObvFigureDescription"],
      obverse_figure_relationship: record["ObvFigureRelationship"],
      obverse_legend: record["ObvLeg"],
      obverse_orientation: nil, # lookup
      obverse_part: nil, # lookup
      obverse_symbol: nil, # lookup
      reverse_attributes: nil, # nested. attr image is not displayed
      reverse_figure: nil, # lookup
      reverse_figure_description: record["RevFigureDescription"],
      reverse_figure_relationship: record["RevFigureRelationship"],
      reverse_legend: record["RevLeg"],
      reverse_orientation: nil, # lookup
      reverse_part: nil, # lookup
      reverse_symbol: nil, # lookup
      ruler: nil, # nested
      series: record["Series"],
      shape: record["Shape"],
      subject: nil, # nested
      workshop: record["Workshop"]
    )
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
