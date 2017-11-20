# frozen_string_literal: true
require_relative 'figgy'
Rails.application.config.to_prepare do
  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Figgy.config['repository_path'],
                                file_mover: lambda { |old, new|
                                              FileUtils.mv(old, new)
                                              FileUtils.chmod(0o644, new)
                                            }),
    :disk
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(
      base_path: Figgy.config['repository_path'],
      file_mover: ->(old, new) { FileUtils.ln(old, new, force: true) }
    ),
    :plum_storage
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(
      base_path: Figgy.config['derivative_path'],
      file_mover: PlumDerivativeMover.method(:link_or_copy)
    ),
    :plum_derivatives
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(
      base_path: Figgy.config['repository_path'],
      file_mover: FileUtils.method(:cp)
    ),
    :lae_storage
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(
      base_path: Figgy.config['repository_path'],
      file_mover: FileUtils.method(:cp)
    ),
    :disk_via_copy
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Figgy.config['derivative_path'],
                                file_mover: lambda { |old, new|
                                              FileUtils.mv(old, new)
                                              FileUtils.chmod(0o644, new)
                                            }),
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
    BenchmarkingMetadataAdapter.new(
      Valkyrie::Persistence::Solr::MetadataAdapter.new(
        connection: Blacklight.default_index.connection,
        resource_indexer: CompositeIndexer.new(
          Valkyrie::Indexers::AccessControlsIndexer,
          CollectionIndexer,
          EphemeraBoxIndexer,
          EphemeraFolderIndexer,
          MemberOfIndexer,
          FacetIndexer,
          ProjectIndexer,
          HumanReadableTypeIndexer,
          SortingIndexer,
          ImportedMetadataIndexer
        )
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
  Valkyrie::DerivativeService.services << PlumDerivativeService::Factory.new(
    change_set_persister: ::PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  # ScannedMapDerivativeService needs its own change_set_persister because the
  # derivatives may not be in the primary metadata/file storage.
  Valkyrie::DerivativeService.services << ScannedMapDerivativeService::Factory.new(
    change_set_persister: ::PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  Valkyrie::FileCharacterizationService.services << PlumCharacterizationService
  Valkyrie::FileCharacterizationService.services << GeoCharacterizationService

  [FindByLocalIdentifier, FindByStringProperty, FindEphemeraTermByLabel, FindEphemeraVocabularyByLabel, MemoryEfficientAllQuery, FindProjectFolders, FindIdentifiersToReconcile].each do |query_handler|
    Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
  end
  Valkyrie.logger = Rails.logger
end
