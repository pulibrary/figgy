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
      return unless collection_change_set? && change_set.changed?(:title)
      descendants.each do |resource|
        cs = ChangeSet.for(resource)
        change_set_persister.save(change_set: cs)
      end
    end

    private

      def descendants
        @descendants ||= begin
          wayfinder = Wayfinder.for(change_set.model)
          if wayfinder.respond_to? :ephemera_folders
            wayfinder.ephemera_boxes + wayfinder.ephemera_folders + folders_in_boxes(wayfinder)
          else
            wayfinder.members
          end
        end
      end

      def folders_in_boxes(wayfinder)
        wayfinder.ephemera_boxes.flat_map { |box| Wayfinder.for(box).members }
      end

      def collection_change_set?
        change_set.model.is_a?(Collection) || change_set.model.is_a?(EphemeraProject)
      end
  end
end
