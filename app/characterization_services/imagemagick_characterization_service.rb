# frozen_string_literal: true

# Class for ImageMagick based file characterization service
# defines the ImageMagick based characterization service a ValkyrieFileCharacterization service
class ImagemagickCharacterizationService
  # Retrieve the supported media types specified in the config.
  # @return [Array<String>]
  def self.supported_formats
    Figgy.config[:characterization][:imagemagick][:supported_mime_types]
  end

  attr_reader :file_set, :persister

  # Constructor
  # @param file_set [FileSet] FileSet being characterized
  # @param persister [ChangeSetPersister] persister for the ChangeSet
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
    [:original_file, :intermediate_file, :preservation_file].each do |type|
      target_file = @file_set.try(type)
      next unless target_file
      begin
        @file_object = Valkyrie::StorageAdapter.find_by(id: target_file.file_identifiers[0])
        file_characterization_attributes.each { |k, v| target_file.try("#{k}=", v) }
      rescue => e
        @characterization_error = e
        target_file.error_message = ["Error during characterization: #{e.message}"]
      end
    end
    @file_set = persister.save(resource: @file_set) if save
    raise @characterization_error if @characterization_error
    @file_set
  end

  # Determines the location of the file on disk for the file_set
  # @return Pathname
  def filename
    return Pathname.new(@file_object.io.path) if @file_object.io.respond_to?(:path) && File.exist?(@file_object.io.path)
  end

  def file_characterization_attributes
    {
      width: vips_image.width.to_s,
      height: vips_image.height.to_s,
      mime_type: mime_type,
      checksum: MultiChecksum.for(@file_object),
      size: file_size,
      error_message: [] # Ensure any previous error messages are removed
    }
  end

  def file_size
    File.size(filename)
  end

  def mime_type
    `file --b --mime-type #{Shellwords.escape(filename)}`.strip
  end

  def vips_image
    Vips::Image.new_from_file(filename.to_s)
  end

  # Retrieve the Resource to which the FileSet is attached
  # @return [Resource]
  def parent
    Wayfinder.for(@file_set).parent
  end

  # Determine whether or not this FileSet belongs to an image resource
  # @return [TrueClass, FalseClass]
  def image_resource?
    parent.respond_to?(:image_resource?) && parent.image_resource?
  end

  # Determine whether or not the media type of the FileSet is supported for characterization
  # @return [TrueClass, FalseClass]
  def supported_format?
    !(@file_set.mime_type & self.class.supported_formats).empty?
  end

  # Determine whether or not this FileSet is valid for this characterization
  # @return [TrueClass, FalseClass]
  def valid?
    image_resource? && supported_format?
  end

  # Class for updating characterization attributes on the FileNode
  class FileCharacterizationAttributes < Dry::Struct
    attribute :width, Valkyrie::Types::Integer
    attribute :height, Valkyrie::Types::Integer
    attribute :mime_type, Valkyrie::Types::String
    attribute :checksum, Valkyrie::Types::String
  end
end
