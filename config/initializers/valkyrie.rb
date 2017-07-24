# frozen_string_literal: true
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
  Valkyrie::Persistence::IndexingAdapter.new(
    metadata_adapter: Valkyrie.config.metadata_adapter,
    index_adapter: Valkyrie::MetadataAdapter.find(:index_solr)
  ),
  :indexing_persister
)
