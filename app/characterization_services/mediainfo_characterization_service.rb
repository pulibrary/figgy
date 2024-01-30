# frozen_string_literal: true

# Implements a service for characterizing audiovisual media resources
class MediainfoCharacterizationService
  # Retrieve the supported media types specified in the config.
  # @return [Array<String>]
  def self.supported_formats
    Figgy.config[:characterization][:mediainfo][:supported_mime_types]
  end

  attr_reader :file_set, :persister

  # Constructor
  # @param file_set [FileSet] FileSet in which the primary binary file is stored
  # @param persister [ChangeSetPersister] ChangeSet persister for the FileSet and parent resource
  def initialize(file_set:, persister:)
    @file_set = file_set
    @persister = persister
  end

  # Characterizes the audiovisual media file_set passed into this service
  # Default options are:
  #   save: true
  # @param save [Boolean] should the persister save the file_set after Characterization
  # @return [FileNode]
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

  def duration
    if media.model.video?
      media.duration
    elsif media.model.audio?
      # MediaInfo returns audio duration in milliseconds
      media.duration.to_f / 1000
    end
  end

  def file_characterization_attributes
    {
      date_of_digitization: media_encoded_date,
      producer: media.producer,
      source_media_type: media.originalsourceform,
      duration: duration.to_s, # Floats are not supported as Valkyrie::Types (update: now they are),
      checksum: MultiChecksum.for(@file_object),
      size: media.filesize,
      mime_type: mime_type,
      error_message: [] # Ensure any previous error messages are removed
    }
  end

  def mime_type
    `file --b --mime-type #{Shellwords.escape(filename)}`.strip
  end

  # Determines if the parent of the FileSet is a Recording
  # @return [TrueClass, FalseClass]
  def valid?
    return false if preservation_file.nil?
    (parent.try(:recording?) || parent.try(:image_resource?)) && supported_format?
  end

  private

    # Determine if the media type for the FileSet is supported
    # @return [TrueClass, FalseClass]
    def supported_format?
      !(@file_set.mime_type & self.class.supported_formats).empty? || extension&.include?(".wav") || extension&.include?(".mp4")
    end

    def extension
      preservation_file&.original_filename&.first&.downcase
    end

    # Retrieve the parent resource of the FileSet
    # @return [Resource]
    def parent
      @parent ||= Wayfinder.for(file_set).parent
    end

    # Determines the location of the file on disk for the file_set
    # @return [String]
    def filename
      return @file_object.io.path if @file_object.io.respond_to?(:path) && File.exist?(@file_object.io.path)
    end

    # Extract the MediaInfo tracks for the binary file stored on the FileSet
    # @return [MediaInfo::Tracks]
    def media_info_tracks
      MediaInfo.from(filename)
    end

    # Retrieves the MediaInfo metadata values for video, audio, or general/other tracks
    # (Defaults to the first track of no video or audio metadata is explicitly offered)
    # @return [MediaInfoTracksDecorator]
    def media
      MediaInfoTracksDecorator.new(media_info_tracks)
    end

    # Ensures that the Time value extracted using MediaInfo is properly offset
    # @see MediaInfo::Tracks.sanitize_element_value
    # @return [DateTime]
    def media_encoded_date
      return unless media.encoded_date
      media.encoded_date.to_datetime.utc
    end

    # Retrieves the primary binary file in this FileSet
    # @return [FileNode]
    def preservation_file
      if parent.try(:image_resource?)
        @file_set.primary_file
      else
        @file_set.preservation_file || @file_set.primary_file
      end
    end
end
