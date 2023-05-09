# frozen_string_literal: true
class CloudFixityJob < ApplicationJob
  queue_as :super_low
  delegate :query_service, to: :change_set_persister

  attr_reader :resource_id, :child_property, :child_id, :fixity_status
  # rubocop:disable Style/GuardClause
  # rubocop:disable Metrics/MethodLength
  def perform(status:, resource_id:, child_property:, child_id:)
    @fixity_status = status
    # resource_id is a PreservationObject
    @resource_id = resource_id
    @child_property = child_property
    @child_id = child_id

    # Do not create an event and honeybadger notification if the resource that
    # was being checked no longer exists. This happens on occasion.
    return unless resource_exist?
    event_change_set = EventChangeSet.new(Event.new)
    event_change_set.validate(type: :cloud_fixity, status: updated_status, resource_id: resource_id, child_property: child_property.to_sym, child_id: child_id, current: true)
    raise "Unable to update fixity. Invalid event: #{event_change_set.errors.full_messages.to_sentence}" unless event_change_set.valid?
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      buffered_change_set_persister.save(change_set: previous_event_change_set) if previous_event
      buffered_change_set_persister.save(change_set: event_change_set)
    end
    if fixity_status == "FAILURE"
      Honeybadger.notify("Cloud fixity failure on object with resource id: #{resource_id}, child property: #{child_property}, child id: #{child_id}")
    end
    if updated_status == Event::REPAIRING
      event = Wayfinder.for(resource).current_cloud_fixity_event
      RepairCloudFixityJob.perform_later(event: event)
    end
  end
  # rubocop:enable Style/GuardClause
  # rubocop:enable Metrics/MethodLength

  private

    def updated_status
      @updated_status ||=
        if fixity_status == Event::FAILURE && !previous_event&.repairing?
          Event::REPAIRING
        else
          fixity_status
        end
    end

    def resource_exist?
      query_service.find_by(id: resource_id)
      true
    rescue Valkyrie::Persistence::ObjectNotFoundError
      false
    end

    def resource
      @resource ||= query_service.find_by(id: resource_id)
    end

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

    def query_service
      change_set_persister.query_service
    end
end
