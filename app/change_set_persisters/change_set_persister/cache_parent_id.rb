# frozen_string_literal: true

class ChangeSetPersister
  class CacheParentId
    attr_reader :change_set_persister, :change_set, :post_save_resource
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless change_set.resource.respond_to?(:cached_parent_id)
      return unless append_id || existing_parent || change_set.resource.cached_parent_id.present?
      change_set.resource.cached_parent_id = append_id || existing_parent&.id
    end

    def existing_parent
      return nil unless change_set.resource.persisted?
      @existing_parent ||=
        begin
          wayfinder = Wayfinder.for(change_set.resource)
          wayfinder.parent if wayfinder.respond_to? :parent
        end
    end

    delegate :append_id, to: :change_set
  end
end
