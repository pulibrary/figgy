# frozen_string_literal: true

# Class for raster resource file characterization service
class RasterCharacterizationService
  attr_reader :file_node, :persister
  def initialize(file_node:, persister:)
    @file_node = file_node
    @persister = persister
  end

  # characterizes the file_node passed into this service
  # Default options are:
  #   save: true
  # @param save [Boolean] should the persister save the file_node after Characterization
  # @return [FileNode]
  # @example characterize a file and persist the changes by default
  #   Valkyrie::FileCharacterizationService.for(file_node, persister).characterize
  # @example characterize a file and do not persist the changes
  #   Valkyrie::FileCharacterizationService.for(file_node, persister).characterize(save: false)
  def characterize(save: true)
    unzip_raster if zip_file?
    new_file = original_file.new(file_characterization_attributes.to_h)
    @file_node.file_metadata = @file_node.file_metadata.select { |x| x.id != new_file.id } + [new_file]
    @persister.save(resource: @file_node) if save
    clean_up_zip_directory if zip_file?
    @file_node
  end

  # Removes unzipped files
  def clean_up_zip_directory
    FileUtils.rm_r(zip_file_directory)
  end

  # Attributes to apply to the file node
  # @return [Hash]
  def file_characterization_attributes
    {
      mime_type: raster_mime_type
    }
  end

  # Determines the location of the file on disk for the file_node
  # @return [Pathname]
  def filename
    return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
  end

  # Provides the file attached to the file_node
  # @return [Valkyrie::StorageAdapter::File]
  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
  end

  # Service that provides information about a raster dataset
  # @return [GeoWorks::Derivatives::Processors::Raster::Info]
  def info_service
    @info_service ||= GeoWorks::Derivatives::Processors::Raster::Info.new(raster_path)
  end

  def original_file
    @file_node.original_file
  end

  def parent
    file_node.decorate.parent
  end

  # Gets a raster's 'geo mime type' by looking up the format's driver in a controlled vocabulary.
  # If the driver is not found, the original mime_type is returned.
  def raster_mime_type
    term = ControlledVocabulary::GeoRasterFormat.new.all.find { |x| x.definition == info_service.driver }
    term ? term.value : original_file.mime_type
  end

  # Path to the raster dataset. The path points to a directory for file formats that are saved as zip files.
  # The path points to the original file for formats that are not saved as zip files.
  # @return [String]
  def raster_path
    @raster_path ||= filename
  end

  # Uncompresses a zipped raster file and sets raster_path variable to the resulting directory.
  def unzip_raster
    system "unzip -o -j #{filename} -d #{zip_file_directory}" unless File.directory?(zip_file_directory)
    @raster_path = zip_file_directory
  end

  def valid?
    parent.is_a?(RasterResource)
  end

  # Tests if original file is a zip file
  # @return [Boolean]
  def zip_file?
    @zip_file ||= original_file.mime_type == ["application/zip"]
  end

  # Path to directory in which to extraxt zip file
  # @return [String]
  def zip_file_directory
    "#{File.dirname(filename)}/#{File.basename(filename, '.zip')}"
  end
end
