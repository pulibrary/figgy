# frozen_string_literal: true
class CloudFixityJob < ApplicationJob
  queue_as :super_low
  delegate :query_service, to: :change_set_persister

  attr_reader :resource_id, :child_property, :child_id
  # rubocop:disable Style/GuardClause
  def perform(status:, resource_id:, child_property:, child_id:)
    @resource_id = resource_id
    @child_property = child_property
    @child_id = child_id
    event_change_set = EventChangeSet.new(Event.new)
    event_change_set.validate(type: :cloud_fixity, status: status, resource_id: resource_id, child_property: child_property.to_sym, child_id: child_id, current: true)
    raise "Unable to update fixity. Invalid event: #{event_change_set.errors.full_messages.to_sentence}" unless event_change_set.valid?
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      buffered_change_set_persister.save(change_set: previous_event_change_set) if previous_event
      buffered_change_set_persister.save(change_set: event_change_set)
    end
    if status == "FAILURE"
      Honeybadger.notify("Cloud fixity failure on object with resource id: #{resource_id}, child property: #{child_property}, child id: #{child_id}")
    end
  end
  # rubocop:enable Style/GuardClause
  # rubocop:enable Metrics/MethodLength

  private

    def previous_event_change_set
      return unless previous_event
      ChangeSet.for(previous_event).tap do |cs|
        cs.validate(current: false)
      end
    end

    def previous_event
      @previous_event ||= query_service.custom_queries.find_by_property(
        property: :metadata,
        value: {
          type: :cloud_fixity,
          resource_id: Valkyrie::ID.new(resource_id),
          child_property: child_property,
          child_id: Valkyrie::ID.new(child_id),
          current: true
        },
        model: Event
      ).first
    end

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.default
    end
end