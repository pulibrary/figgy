# frozen_string_literal: true
class ChangeSetPersister
  class AppendArtistToParent
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :query_service, :persister, :transaction?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless change_set.respond_to?(:artist_parent_id) && artist_parent_id.present?
      add_artist_to_parent
      persister.save(resource: post_save_resource) unless transaction?
    end

    def parent
      @parent ||= query_service.find_by(id: artist_parent_id)
    end

    def add_artist_to_parent
      return unless parent.respond_to?(:numismatic_artist_ids)
      parent.numismatic_artist_ids = parent.numismatic_artist_ids + [post_save_resource.id]
      persister.save(resource: parent)
    end

    delegate :artist_parent_id, to: :change_set
  end
end
