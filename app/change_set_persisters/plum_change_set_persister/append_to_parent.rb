# frozen_string_literal: true
class PlumChangeSetPersister
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
      parent.thumbnail_id = post_save_resource.id if parent.respond_to?(:thumbnail_id) && parent.member_ids.blank?
      parent.member_ids = parent.member_ids + [post_save_resource.id]
      persister.save(resource: parent)
      # Re-save to solr unless it's going to be done by save_all
      persister.save(resource: post_save_resource) unless transaction?
    end

    def parent
      @parent ||= query_service.find_by(id: append_id)
    end

    delegate :append_id, to: :change_set
  end
end
