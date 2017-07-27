# frozen_string_literal: true
Rails.application.config.to_prepare do
  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Rails.root.join("tmp", "files")),
    :test_disk
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Rails.root.join("tmp", "more_files")),
    :disk
  )

  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Postgres::MetadataAdapter.new,
    :postgres
  )

  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Memory::MetadataAdapter.new,
    :memory
  )

  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Solr::MetadataAdapter.new(
      connection: Blacklight.default_index.connection,
      resource_indexer: Valkyrie::Indexers::AccessControlsIndexer
    ),
    :index_solr
  )

  Valkyrie::MetadataAdapter.register(
    IndexingAdapter.new(
      metadata_adapter: Valkyrie.config.metadata_adapter,
      index_adapter: Valkyrie::MetadataAdapter.find(:index_solr)
    ),
    :indexing_persister
  )
end
