# frozen_string_literal: true

# Factory class for automatically finding the appropriate wayfinder for a given
# Valkyrie::Resource.
# @example Instantiating a Wayfinder for a ScannedResource
#   Wayfinder.for(ScannedResource.new) # => #<ScannedResourceWayfinder>
class Wayfinder < BaseWayfinder
  class_attribute :registered_wayfinders
  self.registered_wayfinders = {
    Collection => CollectionWayfinder,
    EphemeraFolder => EphemeraFolderWayfinder,
    EphemeraProject => EphemeraProjectWayfinder,
    EphemeraField => EphemeraFieldWayfinder,
    ScannedResource => ScannedResourceWayfinder,
    EphemeraBox => EphemeraBoxWayfinder,
    EphemeraTerm => EphemeraTermWayfinder,
    FileSet => FileSetWayfinder,
    FileSetChangeSet => FileSetWayfinder,
    EphemeraVocabulary => EphemeraVocabularyWayfinder,
    Playlist => PlaylistWayfinder,
    Numismatics::Coin => Numismatics::CoinWayfinder,
    Numismatics::Accession => Numismatics::AccessionWayfinder,
    Numismatics::Artist => Numismatics::ArtistWayfinder,
    Numismatics::Citation => Numismatics::CitationWayfinder,
    Numismatics::Firm => Numismatics::FirmWayfinder,
    Numismatics::Loan => Numismatics::LoanWayfinder,
    Numismatics::Issue => Numismatics::IssueWayfinder,
    Numismatics::Monogram => Numismatics::MonogramWayfinder,
    Numismatics::Person => Numismatics::PersonWayfinder,
    Numismatics::Place => Numismatics::PlaceWayfinder,
    Numismatics::Provenance => Numismatics::ProvenanceWayfinder,
    Numismatics::Reference => Numismatics::ReferenceWayfinder,
    RasterResource => RasterResourceWayfinder,
    ScannedMap => ScannedMapWayfinder,
    VectorResource => VectorResourceWayfinder,
    Event => EventWayfinder,
    PreservationObject => PreservationObjectWayfinder,
    Preserver::BlindImporter::FileMetadataAdapter::QueryService::FileMetadataResource => Preserver::BlindImporter::FileMetadataAdapter::QueryService::BlindImporterMetadataWayfinder
  }

  def self.for(resource)
    factory = registered_wayfinders[resource.class] || self
    factory.new(resource: resource)
  end

  relationship_by_property :members, property: :member_ids
  relationship_by_property :collections, property: :member_of_collection_ids
  inverse_relationship_by_property :parents, property: :member_ids, singular: true
end
