# frozen_string_literal: true
class ChangeSetPersister
  class ReindexCollectionMembers
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :query_service, :persister, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set_persister = change_set_persister
      @change_set = change_set
    end

    def run
      return unless change_set.model.is_a?(Collection) && change_set.changed?(:title)
      children.each do |resource|
        cs = DynamicChangeSet.new(resource)
        change_set_persister.save(change_set: cs)
      end
    end

    private

      def children
        @children ||= Wayfinder.for(change_set.model).members
      end
  end
end
