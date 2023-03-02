# frozen_string_literal: true

namespace :figgy do
  desc "emails collection owners"
  task send_collection_reports: :environment do
    collections = Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: Collection)
    collections.each do |collection|
      CollectionsMailer.with(collection: collection).owner_report.deliver_now
    end
  end
end
