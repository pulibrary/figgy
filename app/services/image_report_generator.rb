# frozen_string_literal: true
# Generates a report of image and resource counts for the given collections over
# the given date range, split by visibility. This report is used for informing
# Special Collections about how many images were taken for them.
class ImageReportGenerator
  attr_reader :collection_ids, :date_range, :filter_microfilm
  # Microfilm digitization is usually excluded from these reports.
  def initialize(collection_ids:, date_range:, filter_microfilm: true)
    @collection_ids = collection_ids
    @date_range = date_range
    @filter_microfilm = filter_microfilm
  end

  def write(path:)
    CSV.open(path, "w") do |csv|
      csv << headers
      csv_rows.each do |row|
        csv << row
      end
    end
  end

  def to_csv
    CSV.generate do |csv|
      csv << headers
      csv_rows.each do |row|
        csv << row
      end
    end
  end

  def headers
    [
      "Figgy Collection",
      "Open Titles",
      "Private Titles",
      "Reading Room Titles",
      "Princeton Only Titles",
      "Open Image Count",
      "Private Image Count",
      "Reading Room Image Count",
      "Princeton Only Image Count"
    ]
  end

  def csv_rows
    collection_ids.map do |collection_id|
      CollectionReport.new(collection_id: collection_id, date_range: date_range, filter_microfilm: filter_microfilm).to_row
    end
  end
end
