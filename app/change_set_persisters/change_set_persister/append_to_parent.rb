# frozen_string_literal: true
class ChangeSetPersister
  class AppendToParent
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :query_service, :persister, :transaction?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless append_id.present?
      return if post_save_resource.id == append_id
      remove_from_old_parent
      add_to_new_parent
      # Re-save to solr unless it's going to be done by save_all
      persister.save(resource: post_save_resource) unless transaction?
    end

    def new_parent
      @new_parent ||= query_service.find_by(id: append_id)
    end

    def add_to_new_parent
      new_parent.thumbnail_id = post_save_resource.id if new_parent.respond_to?(:thumbnail_id) && new_parent.member_ids.blank?
      new_parent.member_ids = new_parent.member_ids + [post_save_resource.id]
      persister.save(resource: new_parent)
    end

    def old_parent
      @old_parent ||=
        begin
          wayfinder = Wayfinder.for(post_save_resource)
          wayfinder.parent if wayfinder.respond_to? :parent
        end
    end

    def remove_from_old_parent
      return unless old_parent
      old_parent.thumbnail_id = nil if old_parent.respond_to?(:thumbnail_id) && (old_parent.thumbnail_id == post_save_resource.id)
      old_parent.member_ids = old_parent.member_ids - [post_save_resource.id]
      persister.save(resource: old_parent)
    end

    delegate :append_id, to: :change_set
  end
end
