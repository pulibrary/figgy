# frozen_string_literal: true
class Migration::SovietPostersRepair
  def self.call
    new(change_set_persister: ScannedResourcesController.change_set_persister).run!
  end

  attr_reader :change_set_persister
  def initialize(change_set_persister:)
    @change_set_persister = change_set_persister
  end

  def run!
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      broken_resources.each do |resource|
        visibility = Array.wrap(resource.visibility).map { |x| convert_visibility(x) }
        change_set = DynamicChangeSet.new(resource)
        change_set.validate(visibility: visibility)
        buffered_change_set_persister.save(change_set: change_set)
      end
    end
  end

  def convert_visibility(visibility)
    label = Nokogiri::HTML(visibility[:self]).css(".text").text
    ControlledVocabulary.for(:visibility).all.find { |x| x.label == label }.value
  end

  def broken_resources
    @broken_resources ||=
      begin
        change_set_persister.query_service.custom_queries.find_by_property(property: :visibility, value: [{ html_safe: true }])
      end
  end
end
