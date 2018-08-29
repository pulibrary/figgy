# frozen_string_literal: true

# Class for geo resource file characterization service
class GeoCharacterizationService
  attr_reader :file_set, :persister
  def initialize(file_set:, persister:)
    @file_set = file_set
    @persister = persister
  end

  # characterizes the file_set passed into this service
  # Default options are:
  #   save: true
  # @param save [Boolean] should the persister save the file_set after Characterization
  # @return [FileNode]
  # @example characterize a file and persist the changes by default
  #   Valkyrie::Derivatives::FileCharacterizationService.for(file_set, persister).characterize
  # @example characterize a file and do not persist the changes
  #   Valkyrie::Derivatives::FileCharacterizationService.for(file_set, persister).characterize(save: false)
  def characterize(save: true)
    TikaFileCharacterizationService.new(file_set: file_set, persister: persister).characterize
    scanned_map_characterization_service.characterize if scanned_map_characterization_service.valid?
    vector_characterization_service.characterize if vector_characterization_service.valid?
    raster_characterization_service.characterize if raster_characterization_service.valid?
    external_metadata_service.characterize if external_metadata_service.valid?
<<<<<<< HEAD
    @file_set
=======
>>>>>>> d8616123... adds lux order manager to figgy
  end

  def valid?
    parent.respond_to?(:geo_resource?) && parent.geo_resource?
  end

  def parent
    file_set.decorate.parent
  end

  def external_metadata_service
    @external_metadata_service ||= ExternalMetadataCharacterizationService.new(file_set: file_set, persister: persister)
  end

  def scanned_map_characterization_service
    @scanned_map_characterization_service ||= ScannedMapCharacterizationService.new(file_set: file_set, persister: persister)
  end

  def raster_characterization_service
    @raster_characterization_service ||= GdalCharacterizationService::Raster.new(file_set: file_set, persister: persister)
  end

  def vector_characterization_service
    @vector_characterization_service ||= GdalCharacterizationService::Vector.new(file_set: file_set, persister: persister)
  end
end
