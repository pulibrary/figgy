# frozen_string_literal: true
require_relative 'figgy'
Rails.application.config.to_prepare do
  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Figgy.config['repository_path']),
    :disk
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Figgy.config['derivative_path']),
    :derivatives
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
      resource_indexer: CompositeIndexer.new(
        Valkyrie::Indexers::AccessControlsIndexer,
        CollectionIndexer,
        MemberOfIndexer
      )
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

  Hydra::Derivatives.kdu_compress_recipes = Figgy.config['jp2_recipes']

  # Jp2DerivativeService needs its own change_set_persister because the
  # derivatives may not be in the primary metadata/file storage.
  Valkyrie::DerivativeService.services << Jp2DerivativeService::Factory.new(
    change_set_persister: ::PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  Valkyrie::FileCharacterizationService.services << TikaFileCharacterizationService
end
