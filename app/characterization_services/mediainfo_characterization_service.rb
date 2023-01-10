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
    @file_characterization_attributes = {
      date_of_digitization: media_encoded_date,
      producer: media.producer,
      source_media_type: media.originalsourceform,
      duration: duration.to_s, # Floats are not supported as Valkyrie::Types (update: now they are),
      checksum: MultiChecksum.for(file_object),
      size: media.filesize,
      mime_type: mime_type
    }
    new_file = preservation_file.new(@file_characterization_attributes.to_h)
    @file_set.file_metadata = @file_set.file_metadata.select { |x| x.id != new_file.id } + [new_file]
    @file_set = @persister.save(resource: @file_set) if save
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

    # Null Object modeling metadata values from MediaInfo.from
    # @see MediaInfo::Tracks
    class NullTracks
      # Implements the video track accessor
      # @return [nil]
      def video; end

      # Implements the audio track accessor
      # @return [nil]
      def audio; end

      # @return [nil]
      def video?; end

      # @return [nil]
      def audio?; end

      # Implements the accessor for track types
      # Returns only a track of the type "null"
      # @return [Array<String>]
      def track_types
        ["null_track"]
      end

      # Implements the accessor for the sole "null" track
      # @return [NullTracks::Attributes]
      def null_track
        Attributes.new
      end

      # Null Object modeling metadata values for MediaInfo::Tracks
      # @see MediaInfo::Tracks::Attributes
      class Attributes
        # Implements the accessor for the encoded date element
        # @return [nil]
        def encoded_date; end

        # Implements the accessor for the producer element
        # @return [nil]
        def producer; end

        # Implements the accessor for the original source form element
        # @return [nil]
        def originalsourceform; end

        # Implements the accessor for the duration element
        # @return [nil]
        def duration; end

        # Implements the accessor for the filesize element
        # @return [nil]
        def filesize; end
      end
    end

    # Determine if the media type for the FileSet is supported
    # @return [TrueClass, FalseClass]
    def supported_format?
      !(@file_set.mime_type & self.class.supported_formats).empty? || preservation_file&.original_filename&.first&.downcase&.include?(".wav")
    end

    # Retrieve the parent resource of the FileSet
    # @return [Resource]
    def parent
      @parent ||= file_set.decorate.parent
    end

    # Determines the location of the file on disk for the file_set
    # @return [String]
    def filename
      return file_object.io.path if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
    end

    # Extract the MediaInfo tracks for the binary file stored on the FileSet
    # If this fails, the error is logged and a Null Object is returned
    # @return [MediaInfo::Tracks, NullTracks]
    def media_info_tracks
      @media_info ||= MediaInfo.from(filename)
    rescue StandardError => error
      Valkyrie.logger.warn "#{self.class}: Failed to characterize #{filename} using MediaInfo: #{error.message}"
      NullTracks.new
    end

    # Retrieves the MediaInfo metadata values for video, audio, or general/other tracks
    # (Defaults to the first track of no video or audio metadata is explicitly offered)
    # @return [MediaInfoTracksDecorator]
    def media
      @media ||= MediaInfoTracksDecorator.new(media_info_tracks)
    end

    # Ensures that the Time value extracted using MediaInfo is properly offset
    # @see MediaInfo::Tracks.sanitize_element_value
    # @return [DateTime]
    def media_encoded_date
      return unless media.encoded_date
      media.encoded_date.to_datetime.utc
    end

    # Provides the file attached to the file_set
    # @return Valkyrie::StorageAdapter::File
    def file_object
      @file_object ||= Valkyrie::StorageAdapter.find_by(id: preservation_file.file_identifiers[0])
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
