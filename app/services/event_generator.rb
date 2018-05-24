# frozen_string_literal: true
class EventGenerator
  class_attribute :services

  delegate :derivatives_created, to: :generators
  delegate :derivatives_deleted, to: :generators
  delegate :record_created, to: :generators
  delegate :record_deleted, to: :generators
  delegate :record_updated, to: :generators
  delegate :record_member_updated, to: :generators

  def generators
    @generators ||= CompositeGenerator.new(
      [
        ManifestEventGenerator.new(Figgy.messaging_client),
        GeoblacklightEventGenerator.new(Figgy.geoblacklight_messaging_client),
        GeoserverEventGenerator.new(Figgy.geoserver_messaging_client)
      ]
    )
  end
end
