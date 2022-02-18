# frozen_string_literal: true

# Demo-related tasks should only be run in development or staging
if Rails.env.development? || Rails.env.staging?
  namespace :figgy do
    namespace :delete do
      desc "Delete a collection and all its members"
      task collection_cascading: :environment do
        id = ENV["ID"]
        abort "usage: rake figgy:delete:collection_cascading ID=collectionid" unless id

        metadata_adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        qs = metadata_adapter.query_service
        change_set_persister = ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
        amc = qs.find_by(id: id)
        amc_wayfinder = Wayfinder.for(amc)
        amc_wayfinder.members.each { |member| change_set_persister.delete(change_set: ChangeSet.for(member)) }
        change_set_persister.delete(change_set: ChangeSet.for(amc))
      end
    end
  end
end
