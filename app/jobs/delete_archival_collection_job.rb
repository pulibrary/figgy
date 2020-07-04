# frozen_string_literal: true
class DeleteArchivalCollectionJob < ApplicationJob
  def perform(id:)
    qs = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    resources = qs.custom_queries.find_by_property(property: :archival_collection_code,
                                                   value: id)
    if resources.count.zero?
      Rails.logger.info("Archival collection #{id} does not exist, can't delete members")
    else
      Rails.logger.info("removing #{resources.count} resources from collection #{id}.")
      change_set_persister = ScannedResourcesController.change_set_persister
      resources.each do |resource|
        change_set = ChangeSet.for(resource)
        change_set_persister.delete(change_set: change_set)
      end
    end
  end
end
