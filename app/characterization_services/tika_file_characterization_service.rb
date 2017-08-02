# frozen_string_literal: true

# Class for Apache Tika based file characterization service
# defines the Apache Tika based characterization service a ValkyrieFileCharacterization service
# @since 0.1.0
class TikaFileCharacterizationService
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
    result = JSON.parse(json_output).last
    @file_characterization_attributes = { width: result['tiff:ImageWidth'], height: result['tiff:ImageLength'], mime_type: result['Content-Type'], checksum: checksum }
    @file_node = @file_node.new(@file_characterization_attributes.to_h)
    @persister.save(resource: @file_node) if save
    @file_node
  end

  # Provides the SHA256 hexdigest string for the file
  # @return String
  def checksum
    md5 = Digest::MD5.new
    sha256 = Digest::SHA256.new
    sha1 = Digest::SHA1.new
    while (chunk = file_object.read(1024))
      md5.update chunk
      sha256.update chunk
      sha1.update chunk
    end
    MultiChecksum.new(
      sha256: sha256,
      md5: md5,
      sha1: sha1
    )
  end

  def json_output
    "[#{RubyTikaApp.new(filename.to_s).to_json.gsub('}{', '},{')}]"
  end

  # Determines the location of the file on disk for the file_node
  # @return Pathname
  def filename
    return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
  end

  # Provides the file attached to the file_node
  # @return Valkyrie::FileRepository::File
  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: @file_node.file_identifiers[0])
  end

  def valid?
    true
  end

  # Class for updating characterization attributes on the FileNode
  class FileCharacterizationAttributes < Dry::Struct
    attribute :width, Valkyrie::Types::Int
    attribute :height, Valkyrie::Types::Int
    attribute :mime_type, Valkyrie::Types::String
    attribute :checksum, Valkyrie::Types::String
  end
end
