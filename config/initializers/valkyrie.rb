# frozen_string_literal: true
require_relative 'figgy'
Rails.application.config.to_prepare do
  Valkyrie::StorageAdapter.register(
    InstrumentedStorageAdapter.new(
      storage_adapter: Valkyrie::Storage::Disk.new(
        base_path: Figgy.config['repository_path'],
        file_mover: lambda { |old, new|
                      FileUtils.mv(old, new)
                      FileUtils.chmod(0o644, new)
                    }
      ),
      tracer: Datadog.tracer
    ),
    :disk
  )

  Valkyrie::StorageAdapter.register(
    InstrumentedStorageAdapter.new(
      storage_adapter: Valkyrie::Storage::Disk.new(
        base_path: Figgy.config['repository_path'],
        file_mover: ->(old, new) { FileUtils.ln(old, new, force: true) }
      ),
      tracer: Datadog.tracer
    ),
    :plum_storage
  )

  Valkyrie::StorageAdapter.register(
    InstrumentedStorageAdapter.new(
      storage_adapter:  Valkyrie::Storage::Disk.new(
        base_path: Figgy.config['derivative_path'],
        file_mover: PlumDerivativeMover.method(:link_or_copy)
      ),
      tracer: Datadog.tracer
    ),
    :plum_derivatives
  )

  Valkyrie::StorageAdapter.register(
    InstrumentedStorageAdapter.new(
      storage_adapter: Valkyrie::Storage::Disk.new(
        base_path: Figgy.config['repository_path'],
        file_mover: FileUtils.method(:cp)
      ),
      tracer: Datadog.tracer
    ),
    :lae_storage
  )

  Valkyrie::StorageAdapter.register(
    InstrumentedStorageAdapter.new(
      storage_adapter: Valkyrie::Storage::Disk.new(
        base_path: Figgy.config['repository_path'],
        file_mover: FileUtils.method(:cp)
      ),
      tracer: Datadog.tracer
    ),
    :disk_via_copy
  )

  Valkyrie::StorageAdapter.register(
    InstrumentedStorageAdapter.new(
      storage_adapter: Valkyrie::Storage::Disk.new(
        base_path: Figgy.config['derivative_path'],
        file_mover: lambda { |old, new|
                      FileUtils.mv(old, new)
                      FileUtils.chmod(0o644, new)
                    }
      ),
      tracer: Datadog.tracer
    ),
    :derivatives
  )

  Valkyrie::StorageAdapter.register(
    InstrumentedStorageAdapter.new(
      storage_adapter: Valkyrie::Storage::Disk.new(
        base_path: Figgy.config['geo_derivative_path'],
        file_mover: lambda { |old, new|
                      FileUtils.mv(old, new)
                      FileUtils.chmod(0o644, new)
                    }
      ),
      tracer: Datadog.tracer
    ),
    :geo_derivatives
  )

  Valkyrie::StorageAdapter.register(
    InstrumentedStorageAdapter.new(
      storage_adapter: Bagit::StorageAdapter.new(
        base_path: Figgy.config["bag_path"]
      ),
      tracer: Datadog.tracer
    ),
    :bags
  )

  Valkyrie::MetadataAdapter.register(
    Bagit::MetadataAdapter.new(
      base_path: Figgy.config["bag_path"]
    ),
    :bags
  )

  Valkyrie::MetadataAdapter.register(
    InstrumentedAdapter.new(
      metadata_adapter: Valkyrie::Persistence::Postgres::MetadataAdapter.new,
      tracer: Datadog.tracer
    ),
    :postgres
  )

  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Memory::MetadataAdapter.new,
    :memory
  )

  Valkyrie::MetadataAdapter.register(
    InstrumentedAdapter.new(
      metadata_adapter: Valkyrie::Persistence::Solr::MetadataAdapter.new(
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
      ),
      tracer: Datadog.tracer
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
  Valkyrie::Derivatives::DerivativeService.services << PlumDerivativeService::Factory.new(
    change_set_persister: ::PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  Valkyrie::Derivatives::DerivativeService.services << ScannedMapDerivativeService::Factory.new(
    change_set_persister: ::PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  Valkyrie::Derivatives::DerivativeService.services << VectorResourceDerivativeService::Factory.new(
    change_set_persister: ::PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:geo_derivatives)
    )
  )

  Valkyrie::Derivatives::DerivativeService.services << RasterResourceDerivativeService::Factory.new(
    change_set_persister: ::PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:geo_derivatives)
    )
  )

  Valkyrie::Derivatives::FileCharacterizationService.services << PlumCharacterizationService
  Valkyrie::Derivatives::FileCharacterizationService.services << GeoCharacterizationService

  [
    FindByLocalIdentifier,
    FindByStringProperty,
    FindEphemeraTermByLabel,
    FindEphemeraVocabularyByLabel,
    MemoryEfficientAllQuery,
    FindProjectFolders,
    FindIdentifiersToReconcile,
    FileSetsSortedByUpdated,
    FindFixityFailures,
    CountMembers,
    FindUnrelated,
    FindUnrelatedParents
  ].each do |query_handler|
    Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
  end

  [FindMissingThumbnailResources].each do |solr_query_handler|
    Valkyrie::MetadataAdapter.find(:index_solr).query_service.custom_queries.register_query_handler(solr_query_handler)
  end

  Valkyrie.logger = Rails.logger
end
