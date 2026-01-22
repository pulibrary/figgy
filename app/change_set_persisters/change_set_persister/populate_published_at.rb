class ChangeSetPersister
  class PopulatePublishedAt
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.resource.respond_to?(:state)
      return unless change_set.resource.respond_to?(:published_at)
      return unless needs_updating?(change_set)

      change_set.model.published_at = DateTime.now
      change_set
    end

    private

      # Determine whether or not the changes being persisted
      # mean the resource is newly published
      # @param change_set [ChangeSet]
      # @return [Boolean]
      def needs_updating?(change_set)
        # return false if change_set.resource.published_at
        change_set.changed?(:state) &&
          change_set.resource.decorate.published_state?
      end
  end
end
