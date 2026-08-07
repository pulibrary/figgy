class ChangeSetPersister
  class RemoveFromCollection
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return if change_set.try(:remove_collection_ids).blank?
      change_set.member_of_collection_ids = (change_set.member_of_collection_ids || []) - change_set.remove_collection_ids
      unhighlight_removed_collections
    end

    private

      # If a resource leaves a linked collection,
      # remove that id from the featurable list
      def unhighlight_removed_collections
        featurable = change_set.try(:featurable)
        return if featurable.blank?
        change_set.featurable = featurable - change_set.remove_collection_ids
      end
  end
end
