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
    return unless image_valid?
    @file_characterization_attributes = {
      width: image.width.to_s,
      height: image.height.to_s,
      mime_type: image.mime_type,
      checksum: MultiChecksum.for(file_object),
      size: image.size
    }
    new_file = original_file.new(@file_characterization_attributes.to_h)
    @file_set.file_metadata = @file_set.file_metadata.select { |x| x.id != new_file.id } + [new_file]
    @file_set = @persister.save(resource: @file_set) if save
    @file_set
  end

  # Determines the location of the file on disk for the file_set
  # @return Pathname
  def filename
    return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
  end

  # Retrieve the image handler from MiniMagick
  # @return [MiniMagick::Image]
  def image
    @image ||= MiniMagick::Image.open(filename)
  rescue MiniMagick::Invalid
    # Proceed as if this is not an image
    nil
  end

  def image_valid?
    File.size(filename).positive? && image.present?
  end

  # Provides the file attached to the file_set
  # @return Valkyrie::StorageAdapter::File
  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
  end

  # Retrieve the master file from the FileSet
  # @return [FileMetadata]
  def original_file
    @file_set.primary_file
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
