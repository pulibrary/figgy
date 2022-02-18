# frozen_string_literal: true

class Preserver::BlindImporter::FileMetadataAdapter::QueryService
  # Class used as an adapter for generating paths to be used in
  # Preserver::BlindImporter::FileMetadataAdapter::QueryService, so that
  # Preserver::BlindImporter::BlindImporterMetadataWayfinder can find parents to
  # be used in Preserver::NestedStoragePath.
  class FileMetadataResource < Valkyrie::Resource
    attribute :ancestors
  end
end
