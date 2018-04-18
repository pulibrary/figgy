# frozen_string_literal: true
class BagValidationJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(resource_id)
    resource = query_service.find_by(id: Valkyrie::ID.new(resource_id))

    if Bagit::BagValidator.validate(bag_path: bag_path(resource_id))
      resource.bag_validation_success = [1]
      resource.bag_validation_last_success_date = [Time.now.utc]
    else
      resource.bag_validation_success = [0]
    end

    metadata_adapter.persister.buffer_into_index do |buffered_adapter|
      buffered_adapter.persister.save(resource: resource)
    end
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def bag_path(resource_id)
      Pathname.new(Figgy.config["bag_path"]).join(resource_id.to_s)
    end
end
