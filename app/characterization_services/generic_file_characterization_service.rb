class GenericFileCharacterizationService
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
    original_characterizer = Valkyrie::Derivatives::FileCharacterizationService.for(file_set: @file_set, persister: @persister)
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
    # Now that we've set the generic attributes, see if our mime_type
    # identification gets us a new and better characterizer.
    new_characterizer = Valkyrie::Derivatives::FileCharacterizationService.for(file_set: @file_set, persister: @persister)
    begin
      new_characterizer.characterize(save: false) unless new_characterizer.class != original_characterizer.class
    # Inherit any error handling.
    rescue => e
      @characterization_error = e
    end
    @file_set = persister.save(resource: @file_set) if save
    raise @characterization_error if @characterization_error
    @file_set
  end

  def file_characterization_attributes
    {
      mime_type: mime_type,
      checksum: MultiChecksum.for(@file_object),
      size: @file_object.size.to_s,
      error_message: [] # Ensure any previous error messages are removed
    }
  end

  # Determines the location of the file on disk for the file_set
  # @return Pathname
  def filename
    Pathname.new(@file_object.io.path) if @file_object.io.respond_to?(:path) && File.exist?(@file_object.io.path)
  end

  def tika_config
    Rails.root.join("config", "tika-config.xml").to_s
  end

  def mime_type
    `file --b --mime-type #{Shellwords.escape(filename)}`.strip
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
