# frozen_string_literal: true

# Class for Apache Tika based file characterization service
# defines the Apache Tika based characterization service a ValkyrieFileCharacterization service
class TikaFileCharacterizationService
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
    [:original_file, :intermediate_file, :preservation_file].each do |type|
      target_file = @file_set.try(type)
      next unless target_file
      @file_object = Valkyrie::StorageAdapter.find_by(id: target_file.file_identifiers[0])
      new_file = target_file.new(file_characterization_attributes.to_h)
      @file_set.file_metadata = file_set.file_metadata.select { |x| x.id != new_file.id } + [new_file]
    end
    @file_set = persister.save(resource: @file_set) if save
    @file_set
  end

  def json_output
    "[#{RubyTikaApp.new(filename.to_s.gsub("'", %q('"'"')), tika_config).to_json.gsub('}{', '},{')}]"
  end

  def file_characterization_attributes
    result = JSON.parse(json_output).last
    {
      width: result["tiff:ImageWidth"],
      height: result["tiff:ImageLength"],
      mime_type: result["Content-Type"],
      checksum: MultiChecksum.for(@file_object),
      size: result["Content-Length"],
      bits_per_sample: result["tiff:BitsPerSample"],
      x_resolution: result["tiff:XResolution"],
      y_resolution: result["tiff:YResolution"],
      camera_model: result["Model"],
      software: result["Software"]
    }
  end

  # Determines the location of the file on disk for the file_set
  # @return Pathname
  def filename
    return Pathname.new(@file_object.io.path) if @file_object.io.respond_to?(:path) && File.exist?(@file_object.io.path)
  end

  def tika_config
    Rails.root.join("config", "tika-config.xml").to_s
  end

  def valid?
    true
  end

  # Class for updating characterization attributes on the FileNode
  class FileCharacterizationAttributes < Dry::Struct
    attribute :width, Valkyrie::Types::Integer
    attribute :height, Valkyrie::Types::Integer
    attribute :mime_type, Valkyrie::Types::String
    attribute :checksum, Valkyrie::Types::String
    attribute :camera_model, Valkyrie::Types::String
    attribute :software, Valkyrie::Types::String
  end
end
