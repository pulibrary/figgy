# frozen_string_literal: true
class FindingAidIdMigrator
  attr_reader :csv_path
  def initialize(csv_path:)
    @csv_path = csv_path
  end

  def run!
    rows.each do |row|
      row = row.to_h
      next unless row["CID"] && row["MMS ID"]
      resources = change_set_persister.query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: row["CID"])
      resources.each do |resource|
        change_set = ChangeSet.for(resource)
        change_set.validate(source_metadata_identifier: row["MMS ID"])
        change_set_persister.save(change_set: change_set)
      end
    end
  end

  def rows
    @rows ||= CSV.read(csv_path, headers: true)
  end

  def change_set_persister
    ChangeSetPersister.default
  end
end
