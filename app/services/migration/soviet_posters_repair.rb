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
        genre = Array.wrap(resource.genre).map { |x| x[:":id"] }
        geo_subject = Array.wrap(resource.geo_subject).map { |x| x[:":id"] }
        geographic_origin = Array.wrap(resource.geographic_origin).map { |x| x[:":id"] }
        language = Array.wrap(resource.language).map { |x| x[:":id"] }
        subject = Array.wrap(resource.subject).map { |x| x[:":id"] }
        change_set = DynamicChangeSet.new(resource)
        change_set.validate(genre: genre, geo_subject: geo_subject, geographic_origin: geographic_origin, language: language, subject: subject)
        buffered_change_set_persister.save(change_set: change_set)
      end
    end
  end

  def broken_resources
    @broken_resources ||=
      begin
        change_set_persister.query_service.custom_queries.find_by_property(property: :subject, value: [{ ":read_groups": [] }])
      end
  end
end
