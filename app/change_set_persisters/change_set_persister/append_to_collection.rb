# frozen_string_literal: true
class ChangeSetPersister
  class AppendToCollection
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.try(:append_collection_ids).present?
      change_set.member_of_collection_ids = (change_set.member_of_collection_ids || []) + change_set.append_collection_ids
    end
  end
end
