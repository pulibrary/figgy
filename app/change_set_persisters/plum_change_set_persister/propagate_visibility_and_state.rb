# frozen_string_literal: true
class PlumChangeSetPersister
  class PropagateVisibilityAndState
    attr_reader :change_set_persister, :change_set
    delegate :query_service, :persister, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return if !change_set.changed?(:visibility) && !change_set.changed?(:state)
      members.each do |member|
        member.read_groups = change_set.read_groups if change_set.read_groups
        member.state = change_set.state if change_set.state && member.respond_to?(:state)
        persister.save(resource: member)
      end
    end

    def members
      query_service.find_members(resource: change_set.resource).select do |x|
        !x.is_a?(FileSet)
      end
    end
  end
end
