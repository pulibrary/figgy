# frozen_string_literal: true

# Base class for GDAL/OGR characterization services from GeoDerivatives
class GdalCharacterizationService
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
  #   Valkyrie::FileCharacterizationService.for(file_set, persister).characterize
  # @example characterize a file and do not persist the changes
  #   Valkyrie::FileCharacterizationService.for(file_set, persister).characterize(save: false)
  # rubocop:disable Metrics/MethodLength
  def characterize(save: true)
    [:original_file, :intermediate_file, :preservation_file].each do |type|
      @target_file = @file_set.try(type)
      next unless @target_file
      begin
        @file_object = Valkyrie::StorageAdapter.find_by(id: @target_file.file_identifiers[0])
        @dataset_path = filename
        unzip_original_file if zip_file?
        file_characterization_attributes.each { |k, v| @target_file.try("#{k}=", v) }
        @target_file.error_message = []
      rescue => e
        @characterization_error = e
        @target_file.error_message = ["Error during characterization: #{e.message}"]
      ensure
        clean_up_zip_directory if zip_file?
      end
    end
    @file_set = persister.save(resource: @file_set) if save
    raise @characterization_error if @characterization_error
    @file_set
  end
  # rubocop:enable Metrics/MethodLength

  # Removes unzipped files
  def clean_up_zip_directory
    FileUtils.rm_rf(zip_file_directory)
  end

  # Determines the location of the file on disk for the file_set
  # @return [Pathname]
  def filename
    return Pathname.new(@file_object.io.path) if @file_object.io.respond_to?(:path) && File.exist?(@file_object.io.path)
  end

  # Gets a file's 'geo mime type' by looking up the format's driver in a controlled vocabulary.
  # If the driver is not found, the original mime_type is returned.
  def mime_type
    term = format_controlled_vocabulary.all.find { |x| x.definition == info_service.driver }
    term ? term.value : primary_file.mime_type
  end

  def primary_file
    @file_set.primary_file
  end

  def parent
    file_set.decorate.parent
  end

  # Uncompresses a zipped file and sets dataset_path variable to the resulting directory.
  def unzip_original_file
    system %(unzip -qq -o -j "#{filename}" -d #{zip_file_directory}) unless File.directory?(zip_file_directory)
    @dataset_path = zip_file_directory
  end

  # Tests if primary file is a zip file
  # @return [Boolean]
  def zip_file?
    @target_file.mime_type == ["application/zip"]
  end

  # Path to directory in which to extract zip file
  # @return [String]
  def zip_file_directory
    # Get the base file name and remove problematic parens
    basename = File.basename(filename, ".zip").delete("(").delete(")")
    "#{File.dirname(filename)}/#{basename}"
  end

  class Raster < GdalCharacterizationService
    # Controlled vocabulary class for raster formats
    # @return [ControlledVocabulary::GeoRasterFormat]
    def format_controlled_vocabulary
      ControlledVocabulary::GeoRasterFormat.new
    end

    # Attributes to apply to the file node
    # @return [Hash]
    def file_characterization_attributes
      {
        bounds: info_service.bounds,
        mime_type: mime_type
      }
    end

    # Service that provides information about a raster dataset
    # @return [GeoDerivatives::Processors::Raster::Info]
    def info_service
      GeoDerivatives::Processors::Raster::Info.new(@dataset_path)
    end

    def valid?
      parent.is_a?(RasterResource) && primary_file.mime_type != ["application/xml"]
    end
  end

  class Vector < GdalCharacterizationService
    # Controlled vocabulary class for vector formats
    # @return [ControlledVocabulary::GeoVectorFormat]
    def format_controlled_vocabulary
      ControlledVocabulary::GeoVectorFormat.new
    end

    # Attributes to apply to the file node
    # @return [Hash]
    def file_characterization_attributes
      {
        geometry: info_service.geom,
        mime_type: mime_type
      }
    end

    # Service that provides information about a vector dataset
    # @return [GeoDerivatives::Processors::Vector::Info]
    def info_service
      GeoDerivatives::Processors::Vector::Info.new(@dataset_path)
    end

    def valid?
      parent.is_a?(VectorResource) && primary_file.mime_type != ["application/xml"]
    end
  end
end
