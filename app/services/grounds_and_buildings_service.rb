# frozen_string_literal: true
require "csv"
class GroundsAndBuildingsService
  attr_reader :items, :collection, :change_set_persister, :logger
  def initialize(collection, table, change_set_persister, logger: Valkyrie.logger)
    @collection = collection
    @change_set_persister = change_set_persister
    @items = []
    table.each do |row|
      @items << row
    end
  end

  def components
    all = @items.collect do |item|
      "#{collection}_#{item['componentID']}"
    end
    all.uniq
  end

  def children(component_id)
    rows = items.select { |item| item["componentID"] == component_id.split("_").last }
    urls = rows.collect { |row| row["Figgy URL"] }
    urls.map { |url| figgy_id(url) }
  end

  def add_members_to_mvw(mvw)
    change_set = ChangeSet.for(mvw)
    change_set.validate(member_ids: children(mvw.source_metadata_identifier.first))
    change_set_persister.save(change_set: change_set)
  end

def figgy_id(url)
  url.match(/^.*catalog\//).post_match
end

end
