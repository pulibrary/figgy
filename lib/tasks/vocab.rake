# frozen_string_literal: true
namespace :vocab do
  task load: :environment do
    file = ENV["CSV"]
    name = ENV["NAME"]
    columns = {
      label: ENV["LABEL"] || "label",
      tgm: ENV["TGM"] || "tgm_label",
      lcsh: ENV["LCSH"] || "lcsh_label",
      uri: ENV["URI"] || "uri",
      category: ENV["CATEGORY"]
    }

    change_set_persister = PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:lae_storage)
    )

    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      IngestVocabService.new(buffered_change_set_persister, file, name, columns).ingest
    end
  end
end
