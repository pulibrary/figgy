# frozen_string_literal: true
require_relative "figgy"

Rails.application.config.to_prepare do
  # Registers a storage adapter for a *NIX file system
  # Binaries are persisted by invoking "mv" with access limited to read/write for owning users, and read-only for all others
  # NOTE: "mv" may preserve the inode for the file system
  # @see http://manpages.ubuntu.com/manpages/xenial/man1/mv.1.html
  # file_mover should be a lambda or Proc which performs an operation on the file using its path
  # This `mv` ensures that files can be read by any process on the server
  # `644` is the octal value of the bitmask used in order to ensure that the derivative file globally-readable
  # The file system in the server environment was overriding this, specifically for cases where files were saved to...
  # ...the IIIF image server network file share (libimages1) with a file access control octal value of 600 (globally-unreadable)
  # @see https://help.ubuntu.com/community/FilePermissions
  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["repository_path"],
        file_mover: lambda { |old_path, new_path|
          FileUtils.mv(old_path, new_path)
          FileUtils.chmod(0o644, new_path)
        }
      )
    ),
    :primary_disk
  )

  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["fallback_repository_path"],
        file_mover: lambda { |old_path, new_path|
          FileUtils.mv(old_path, new_path)
          FileUtils.chmod(0o644, new_path)
        }
      )
    ),
    :fallback_disk
  )

  Valkyrie::StorageAdapter.register(
    FallbackDiskAdapter.new(
      primary_adapter: Valkyrie::StorageAdapter.find(:primary_disk),
      fallback_adapter: Valkyrie::StorageAdapter.find(:fallback_disk)
    ),
    :disk
  )

  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["stream_derivatives_path"],
        file_mover: lambda { |old_path, new_path|
          FileUtils.mv(old_path, new_path)
          FileUtils.chmod(0o644, new_path)
        }
      )
    ),
    :primary_stream_derivatives
  )

  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["fallback_stream_derivatives_path"],
        file_mover: lambda { |old_path, new_path|
          FileUtils.mv(old_path, new_path)
          FileUtils.chmod(0o644, new_path)
        }
      )
    ),
    :fallback_stream_derivatives
  )

  Valkyrie::StorageAdapter.register(
    FallbackDiskAdapter.new(
      primary_adapter: Valkyrie::StorageAdapter.find(:primary_stream_derivatives),
      fallback_adapter: Valkyrie::StorageAdapter.find(:fallback_stream_derivatives)
    ),
    :stream_derivatives
  )

  # Registers a storage adapter for a *NIX file system
  # Binaries are persisted by invoking "cp" (duplicating the file)
  # NOTE: This doubles the size of binaries being persisted if the repository
  # @see http://manpages.ubuntu.com/manpages/xenial/man1/cp.1.html
  # is deployed on the same file system as the one storing the files being uploaded
  # NOTE: Separate inodes are created
  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["repository_path"],
        file_mover: FileUtils.method(:cp)
      )
    ),
    :primary_disk_via_copy
  )

  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["fallback_repository_path"],
        file_mover: FileUtils.method(:cp)
      )
    ),
    :fallback_disk_via_copy
  )

  Valkyrie::StorageAdapter.register(
    FallbackDiskAdapter.new(
      primary_adapter: Valkyrie::StorageAdapter.find(:primary_disk_via_copy),
      fallback_adapter: Valkyrie::StorageAdapter.find(:fallback_disk_via_copy)
    ),
    :disk_via_copy
  )

  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["ingest_folder_path"],
        file_mover: FileUtils.method(:cp)
      )
    ),
    :ingest_adapter
  )

  Google::Cloud::Storage.configure.timeout = 36_000 # 10 hour timeout
  if ENV["STORAGE_PROJECT"] && ENV["STORAGE_CREDENTIALS"] && !Rails.env.test?
    Shrine.storages = {
      preservation: Shrine::Storage::GoogleCloudStorage.new(bucket: Figgy.config["preservation_bucket"]),
      versioned_preservation: Shrine::Storage::VersionedGoogleCloudStorage.new(bucket: Figgy.config["preservation_bucket"])
    }
    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Shrine.new(
        Shrine.storages[:preservation],
        nil,
        Preserver::NestedStoragePath
      ),
      :google_cloud_storage
    )
    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Shrine.new(
        Shrine.storages[:versioned_preservation],
        nil,
        Preserver::NestedStoragePath
      ),
      :versioned_google_cloud_storage
    )
  else
    # If GCS isn't configured, use a disk persister that saves in the same
    # structure as GCS.
    Valkyrie::StorageAdapter.register(
      GcsFake::Storage.new(
        base_path: Figgy.config["disk_preservation_path"],
        file_mover: FileUtils.method(:cp),
        path_generator: Preserver::NestedStoragePath
      ),
      :google_cloud_storage
    )
    Valkyrie::StorageAdapter.register(
      Valkyrie::StorageAdapter.find(:google_cloud_storage),
      :versioned_google_cloud_storage
    )
  end

  # Registers a storage adapter for a *NIX file system
  # Binaries are persisted by invoking "mv" with access limited to read/write for owning users, and read-only for all others
  # NOTE: "mv" may preserve the inode for the file system
  # @see http://manpages.ubuntu.com/manpages/xenial/man1/mv.1.html
  # This `mv` ensures that files can be read by any process on the server
  # `644` is the octal value of the bitmask used in order to ensure that the derivative file globally-readable
  # The file system in the server environment was overriding this, specifically for cases where files were saved to...
  # ...the IIIF image server network file share (libimages1) with a file access control octal value of 600 (globally-unreadable)
  # @see https://help.ubuntu.com/community/FilePermissions
  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["derivative_path"],
        file_mover: lambda { |old_path, new_path|
          FileUtils.mv(old_path, new_path)
          FileUtils.chmod(0o644, new_path)
        }
      )
    ),
    :primary_derivatives
  )

  Valkyrie::StorageAdapter.register(
    RetryingDiskAdapter.new(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["fallback_derivative_path"],
        file_mover: lambda { |old_path, new_path|
          FileUtils.mv(old_path, new_path)
          FileUtils.chmod(0o644, new_path)
        }
      )
    ),
    :fallback_derivatives
  )

  Valkyrie::StorageAdapter.register(
    FallbackDiskAdapter.new(
      primary_adapter: Valkyrie::StorageAdapter.find(:primary_derivatives),
      fallback_adapter: Valkyrie::StorageAdapter.find(:fallback_derivatives)
    ),
    :derivatives
  )

  if Figgy.config["pyramidals_bucket"].present? && !Rails.env.test?
    Shrine.storages = (Shrine.storages || {}).merge(
      pyramidal_storage: Shrine::Storage::S3.new(
        bucket: Figgy.config["pyramidals_bucket"],
        region: Figgy.config["pyramidals_region"],
        access_key_id: Figgy.config["aws_access_key_id"],
        secret_access_key: Figgy.config["aws_secret_access_key"]
      )
    )
    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Shrine.new(
        Shrine.storages[:pyramidal_storage],
        Shrine::NullVerifier,
        Valkyrie::Storage::Disk::BucketedStorage,
        identifier_prefix: "pyramidal-derivatives"
      ),
      :pyramidal_derivatives
    )
  else
    # Fall back to disk storage for development/test or if S3 is not
    # configured.
    Valkyrie::StorageAdapter.register(
      RetryingDiskAdapter.new(
        Valkyrie::Storage::Disk.new(
          base_path: Figgy.config["pyramidal_derivative_path"],
          file_mover: lambda { |old_path, new_path|
            FileUtils.mv(old_path, new_path)
            FileUtils.chmod(0o644, new_path)
          }
        )
      ),
      :pyramidal_derivatives
    )
  end

  # Registers a storage adapter for a *NIX file system
  # Binaries are persisted by invoking "mv" with access limited to read/write for owning users, and read-only for all others
  # NOTE: "mv" may preserve the inode for the file system
  # @see http://manpages.ubuntu.com/manpages/xenial/man1/mv.1.html
  # This `mv` ensures that files can be read by any process on the server
  # `644` is the octal value of the bitmask used in order to ensure that the derivative file globally-readable
  # The file system in the server environment was overriding this, specifically for cases where files were saved to...
  # ...the IIIF image server network file share (libimages1) with a file access control octal value of 600 (globally-unreadable)
  # @see https://help.ubuntu.com/community/FilePermissions
  if Figgy.config["aws_access_key_id"].present? && Figgy.config["cloud_geo_bucket"].present? && !Rails.env.test?
    Shrine.storages = (Shrine.storages || {}).merge(
      cloud_geo_storage: Shrine::Storage::S3.new(
        bucket: Figgy.config["cloud_geo_bucket"],
        region: Figgy.config["cloud_geo_region"],
        access_key_id: Figgy.config["aws_access_key_id"],
        secret_access_key: Figgy.config["aws_secret_access_key"]
      )
    )
    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Shrine.new(
        Shrine.storages[:cloud_geo_storage],
        Shrine::NullVerifier,
        Valkyrie::Storage::Disk::BucketedStorage,
        identifier_prefix: "cloud-geo-derivatives"
      ),
      :cloud_geo_derivatives
    )
  else
    # Fall back to disk storage for development/test or if S3 is not
    # configured.
    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Disk.new(
        base_path: Figgy.config["test_cloud_geo_derivative_path"],
        file_mover: lambda { |old_path, new_path|
          FileUtils.mv(old_path, new_path)
          FileUtils.chmod(0o644, new_path)
        }
      ),
      :cloud_geo_derivatives
    )
  end

  # Registers a storage adapter for storing a Bag on a *NIX file system
  # @see https://tools.ietf.org/html/draft-kunze-bagit-14
  Valkyrie::StorageAdapter.register(
    Bagit::StorageAdapter.new(
      base_path: Figgy.config["bag_path"]
    ),
    :bags
  )

  # Register a metadata adapter for storing a Bag on a *NIX file system
  # @see https://tools.ietf.org/html/draft-kunze-bagit-14
  # (see Bagit::MetadataAdapter)
  Valkyrie::MetadataAdapter.register(
    Bagit::MetadataAdapter.new(
      base_path: Figgy.config["bag_path"]
    ),
    :bags
  )

  database_configuration = Rails.configuration.database_configuration[Rails.env]
  connection = Sequel.connect(
    user: database_configuration["username"],
    password: database_configuration["password"],
    host: database_configuration["host"],
    port: database_configuration["port"],
    database: database_configuration["database"],
    logger: nil,
    max_connections: database_configuration["pool"],
    pool_timeout: database_configuration["timeout"],
    adapter: :postgres
  ).tap do |conn|
    conn.extension(:connection_validator)
    conn.pool.connection_validation_timeout = -1
  end
  # Registers a metadata adapter for storing resource metadata into PostgreSQL as JSON
  # (see Valkyrie::Persistence::Postgres::MetadataAdapter)
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Sequel::MetadataAdapter.new(
      connection: connection
    ),
    :postgres
  )

  # Registers a metadata adapter for storing resource metadata into memory
  # (see Valkyrie::Persistence::Memory::MetadataAdapter)
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Memory::MetadataAdapter.new,
    :memory
  )

  indexer = CompositeIndexer.new(
    Valkyrie::Indexers::AccessControlsIndexer,
    CollectionIndexer,
    EphemeraBoxIndexer,
    EphemeraFolderIndexer,
    DeletionMarkerIndexer,
    FacetIndexer,
    ProjectIndexer,
    HumanReadableTypeIndexer,
    ImportedMetadataIndexer,
    MemberOfIndexer,
    RightsLabelIndexer,
    CoinIndexer,
    SortingIndexer,
    TitleIndexer,
    TrackIndexer,
    ParallelTestIndexer
  )

  solr_adapter = Valkyrie::Persistence::Solr::MetadataAdapter.new(
    connection: Blacklight.default_index.connection,
    resource_indexer: indexer,
    write_only: true
  )
  if Figgy.index_read_only?
    # Solr adapter will error to rollback database writes via composite adapter
    # Use this when doing a long reindexing process to make sure that CDL
    # continues to work but new items aren't added to the database
    Valkyrie::MetadataAdapter.register(
      ReadOnlyAdapter.new(solr_adapter),
      :index_solr
    )
  else
    # Registers a metadata adapter for storing and indexing resource metadata into Solr
    # (see Valkyrie::Persistence::Solr::MetadataAdapter)
    Valkyrie::MetadataAdapter.register(
      solr_adapter,
      :index_solr
    )
  end

  # Adapter for reindexing - disables commits
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Solr::MetadataAdapter.new(
      connection: Blacklight.default_index.connection,
      resource_indexer: indexer,
      write_only: true,
      soft_commit: false
    ),
    :reindex_solr
  )

  if ENV["CLEAN_REINDEX_SOLR_URL"]
    # Register an indexer for a clean reindex.
    Valkyrie::MetadataAdapter.register(
      Valkyrie::Persistence::Solr::MetadataAdapter.new(
        connection: RSolr.connect(url: ENV["CLEAN_REINDEX_SOLR_URL"]),
        resource_indexer: indexer,
        write_only: true,
        soft_commit: false
      ),
      :clean_reindex_solr
    )
  end

  # Registers a metadata adapter for indexing resource metadata using a registered Solr adapter
  # (see IndexingAdapter)
  Valkyrie::MetadataAdapter.register(
    IndexingAdapter.new(
      metadata_adapter: Valkyrie.config.metadata_adapter,
      index_adapter: Valkyrie::MetadataAdapter.find(:index_solr)
    ),
    :indexing_persister
  )

  # Set the JP2 recipes for KDU compression
  Hydra::Derivatives.kdu_compress_recipes = Figgy.config["jp2_recipes"]

  # Construct and register the derivative service objects for images in the TIFF
  Valkyrie::Derivatives::DerivativeService.services << DefaultDerivativeService::Factory.new(
    change_set_persister: ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  # Construct and register the derivative service objects for images in the GeoTIFF
  Valkyrie::Derivatives::DerivativeService.services << ScannedMapDerivativeService::Factory.new(
    change_set_persister: ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  # Construct and register the derivative service objects for geospatial vector data sets
  Valkyrie::Derivatives::DerivativeService.services << VectorResourceDerivativeService::Factory.new(
    change_set_persister: ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  # Construct and register the derivative service objects for geospatial raster data sets
  Valkyrie::Derivatives::DerivativeService.services << RasterResourceDerivativeService::Factory.new(
    change_set_persister: ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )
  Valkyrie::Derivatives::DerivativeService.services << ExternalMetadataDerivativeService::Factory.new(
    change_set_persister: ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
    )
  )

  Valkyrie::Derivatives::DerivativeService.services << AvDerivativeService::Factory.new(
    change_set_persister: ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:stream_derivatives),
      characterize: false
    )
  )

  Valkyrie::Derivatives::DerivativeService.services << PDFDerivativeService::Factory.new(
    change_set_persister: ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk)
    )
  )

  # Register the service class for no-op characterization short-circuit
  Valkyrie::Derivatives::FileCharacterizationService.services << NullCharacterizationService
  # PDFs
  Valkyrie::Derivatives::FileCharacterizationService.services << PDFCharacterizationService
  # Register the service class for image asset characterization
  Valkyrie::Derivatives::FileCharacterizationService.services << ImagemagickCharacterizationService
  # Register the service class for geospatial asset characterization
  Valkyrie::Derivatives::FileCharacterizationService.services << GeoCharacterizationService
  # Register the service class for audiovisual asset characterization
  Valkyrie::Derivatives::FileCharacterizationService.services << MediainfoCharacterizationService
  # Register the service class for the default asset characterization
  Valkyrie::Derivatives::FileCharacterizationService.services << DefaultCharacterizationService

  # Register custom queries for the default Valkyrie metadata adapter
  # (see Valkyrie::Persistence::CustomQueryContainer)
  [
    AllMmsResourcesQuery,
    FindByLocalIdentifier,
    FindByProperty,
    FindManyByProperty,
    FindEphemeraTermByLabel,
    FindEphemeraVocabularyByLabel,
    MemoryEfficientAllQuery,
    FindProjectFolders,
    FindIdentifiersToReconcile,
    FileSetsSortedByUpdated,
    FindFixityEvents,
    CountMembers,
    FindSavedIds,
    FindMembersWithRelationship,
    FindHighestValue,
    PlaylistsFromRecording,
    CountInverseRelationship,
    FindIdUsageByModel,
    UpdatedArchivalResources,
    FindRandomResourcesByModel,
    CountAllOfModel,
    DeepLocalFixityCount,
    FindDeepChildrenWithProperty,
    FindDeepPreservationObjectCount,
    FindIdsWithPropertyNotEmpty,
    DeepCloudFixityCount,
    PagedAllQuery,
    FindResourcesWithoutMembers,
    PluckEarliestUpdatedAt,
    LatestMemberTimestamp,
    FindBySourceMetadataIdentifier,
    MosaicFingerprintQuery,
    MosaicFileSetQuery,
    FindPersistedMemberIds,
    FindNeverPreservedChildIds,
    FindDeepErroredFileSets,
    FindUncaptionedMembers,
    FindVideoMembers
  ].each do |query_handler|
    Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
  end

  # Register custom queries for the Valkyrie Solr metadata adapter used for indexing
  # (see Valkyrie::Persistence::CustomQueryContainer)
  [FindMissingThumbnailResources, FindInvalidThumbnailResources, FindFacetValues].each do |solr_query_handler|
    Valkyrie::MetadataAdapter.find(:index_solr).query_service.custom_queries.register_query_handler(solr_query_handler)
  end

  # Ensure that the logger used for Valkyrie is the same used by Rails
  Valkyrie.logger = Rails.logger
  Valkyrie::Resource.include Draper::Decoratable
rescue Sequel::DatabaseConnectionError
  Rails.logger.info "Unable to connect to database - skipping Valkyrie initialization."
end
