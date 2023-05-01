# frozen_string_literal: true

# Fixes cloud files by represerving local files if they are good
class RepairCloudFixity
  def self.run(event:)
    new(event: event).run
  end

  attr_reader :event
  def initialize(event:)
    @event = event
  end

  def run
    if child_property == :binary_nodes
      repair_binary_nodes
    else
      repair_metadata
    end
  end

  private

    def preservation_object
      query_service.find_by(id: event.resource_id)
    end

    def resource
      @resource ||= query_service.find_by(id: preservation_object.preserved_object_id)
    end

    def repair_binary_nodes
      # Once we know it's a binary node, resource id is the file set id
      # LocalFixityJob will create a new current local_fixity event
      LocalFixityJob.perform_now(resource.id.to_s)
      local_fixity_event = Wayfinder.for(resource).current_local_fixity_event

      if local_fixity_event.successful?
        # Re-preserve using local file
        Preserver.for(change_set: ChangeSet.for(resource), change_set_persister: ChangeSetPersister.default, force_preservation: true).preserve!
      else
        create_failed_cloud_fixity_event
      end
    end

    def repair_metadata
      Preserver.for(change_set: ChangeSet.for(resource), change_set_persister: ChangeSetPersister.default).preserve!
    end

    def create_failed_cloud_fixity_event
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        buffered_change_set_persister.save(change_set: previous_event_change_set)
        buffered_change_set_persister.save(change_set: event_change_set)
      end
    end

    def child_property
      @child_property ||= event.child_property.to_sym
    end

    def previous_event_change_set
      ChangeSet.for(event).tap do |cs|
        cs.validate(current: false)
      end
    end

    def event_change_set
      EventChangeSet.new(Event.new).tap do |cs|
        cs.validate(type: :cloud_fixity, status: Event::FAILURE, resource_id: event.resource_id, child_property: child_property, child_id: event.child_id, current: true)
      end
    end

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.default
    end

    def query_service
      @query_service ||= change_set_persister.query_service
    end
end
