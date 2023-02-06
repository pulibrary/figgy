# frozen_string_literal: true
class ChangeSetPersister
  class DeleteMembers
    class Factory
      attr_reader :property
      def initialize(property:)
        @property = property
      end

      def new(change_set_persister:, change_set:)
        DeleteMembers.new(change_set_persister: change_set_persister,
                          change_set: change_set,
                          property: property)
      end
    end
    attr_reader :change_set_persister, :change_set, :property
    delegate :query_service, :persister, :transaction?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, property:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @property = property
    end

    def run
      return unless change_set.resource.respond_to?(property)
      ids.map do |id|
        DeleteMemberJob.perform_later(id.to_s, change_set.resource.id.to_s)
      end
    end

    def ids
      change_set.resource.try(property) || []
    end
  end
end
