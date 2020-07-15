# frozen_string_literal: true
require 'csv'
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

  def children(componentID)
    rows = items.select { |item| item['componentID'] == componentID.split('_').last }
    urls = rows.collect { |row| row['Figgy URL'] }
    urls.map { |url| figgyID(url) }
  end

  def mvw(componentID)
    # is there already a mvw?
    mvw = change_set_persister.query_service.custom_queries.find_by_property(
      property: :source_metadata_identifier,
      value: componentID).first
    if mvw.nil?
      ScannedResource.new(source_metadata_identifier: componentID) # import_metadata: true?
    else
      mvw
    end
  end

  def add_members_to_mvw(mvw)
    change_set = ChangeSet.for(mvw)
    change_set.validate(member_ids: children(mvw.source_metadata_identifier.first))
    change_set_persister.save(change_set: change_set)
  end
end


private

def figgyID url
  url.match(/^.*catalog\//).post_match
end
