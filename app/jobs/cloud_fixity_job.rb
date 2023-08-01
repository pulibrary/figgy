# frozen_string_literal: true
class CloudFixityJob < ApplicationJob
  queue_as :super_low
  delegate :query_service, to: :change_set_persister

  attr_reader :preservation_object_id, :child_property, :child_id, :fixity_status
  # rubocop:disable Style/GuardClause
  # rubocop:disable Metrics/MethodLength
  def perform(status:, preservation_object_id:, child_property:, child_id:)
    @fixity_status = status
    @preservation_object_id = preservation_object_id
    @child_property = child_property
    @child_id = child_id

    # Do not create an event and honeybadger notification if the resource that
    # was being checked no longer exists. This happens on occasion.
    return unless resource_exist?
    event_change_set = EventChangeSet.new(Event.new)
    event_change_set.validate(type: :cloud_fixity, status: updated_status, resource_id: preservation_object_id, child_property: child_property.to_sym, child_id: child_id, current: true)
    raise "Unable to update fixity. Invalid event: #{event_change_set.errors.full_messages.to_sentence}" unless event_change_set.valid?
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      previous_events.each do |previous_event|
        buffered_change_set_persister.save(change_set: previous_event_change_set(previous_event))
      end
      buffered_change_set_persister.save(change_set: event_change_set)
    end
    if fixity_status == "FAILURE"
      Honeybadger.notify("Cloud fixity failure on object with preserved resource id: #{preservation_object.preserved_object_id} (preservation object id: #{preservation_object_id})")
    end
    if updated_status == Event::REPAIRING
      event = current_cloud_fixity_event
      RepairCloudFixityJob.perform_later(event_id: event.id.to_s)
    end
  end
  # rubocop:enable Style/GuardClause
  # rubocop:enable Metrics/MethodLength

  private

    def current_cloud_fixity_event
      Wayfinder.for(preservation_object).current_cloud_fixity_events.find { |e| e.child_id.to_s == child_id }
    end

    def updated_status
      @updated_status ||=
        if fixity_status == Event::FAILURE && !previous_events&.first&.repairing?
          Event::REPAIRING
        else
          fixity_status
        end
    end

    def resource_exist?
      query_service.find_by(id: preservation_object_id)
      true
    rescue Valkyrie::Persistence::ObjectNotFoundError
      false
    end

    def preservation_object
      @preservation_object ||= query_service.find_by(id: preservation_object_id)
    end

    def previous_event_change_set(previous_event)
      ChangeSet.for(previous_event).tap do |cs|
        cs.validate(current: false)
      end
    end

    def previous_events
      @previous_events ||= query_service.custom_queries.find_by_property(
        property: :metadata,
        value: previous_event_query,
        model: Event
      )
    end

    def previous_event_query
      query = {
        type: :cloud_fixity,
        resource_id: Valkyrie::ID.new(preservation_object_id),
        child_property: child_property,
        current: true
      }
      # child_id gets re-created on re-preservation for metadata_nodes, so don't
      # find event based on it.
      query[:child_id] = Valkyrie::ID.new(child_id) unless child_property.to_s == "metadata_node"
      query
    end

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.default
    end

    def query_service
      change_set_persister.query_service
    end
end
