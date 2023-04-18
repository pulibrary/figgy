# frozen_string_literal: true
# Finds resources which are marked to be completed when processed, makes sure
# they have files, and makes sure those files are processed, then completes them
# if so.
class AutoCompleter
  def self.run
    ChangeSetPersister.default.buffer_into_index do |buffered_change_set_persister|
      new(change_set_persister: buffered_change_set_persister).run
    end
  end

  attr_reader :change_set_persister
  delegate :query_service, to: :change_set_persister
  def initialize(change_set_persister:)
    @change_set_persister = change_set_persister
  end

  def run
    eligible_resources.each do |resource|
      change_set = ChangeSet.for(resource)
      change_set.validate(state: "complete")
      change_set_persister.save(change_set: change_set) if change_set.valid?
    rescue StandardError
      Honeybadger.notify "Exception occurred trying to auto-complete resource #{resource.id}"
    end
  end

  private

    # Only complete resources which have complete_when_processed, have members,
    # and those members are processed.
    def eligible_resources
      resources_with_members.select do |resource|
        query_service.custom_queries.find_deep_children_with_property(
          resource: resource,
          model: "FileSet",
          property: :processing_status,
          value: "in process",
          count: true
        ).zero?
      end
    end

    def resources_with_members
      complete_when_processed_resources.select do |resource|
        !resource.member_ids.empty?
      end
    end

    def complete_when_processed_resources
      query_service.custom_queries.find_by_property(property: :state, value: "complete_when_processed", lazy: true)
    end
end
