# frozen_string_literal: true

class PlumChangeSetPersister
  class IngestBag
    attr_reader :change_set_persister, :change_set, :post_save_resource

    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    # Key triggering ingest off of the bag_path property existing so we can do
    # it outside of HTML forms.
    def run
      return unless change_set.try(:bag_path).present?
      IngestArchivalMediaBagJob.perform_later(
        collection_component: post_save_resource.source_metadata_identifier.first,
        bag_path: change_set.bag_path.to_s,
        user: user
      )
    end

    def user
      User.where(uid: change_set.depositor.first).first! if change_set.depositor.present?
    end
  end
end
