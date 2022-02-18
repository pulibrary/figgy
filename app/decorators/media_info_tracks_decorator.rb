# frozen_string_literal: true

class MediaInfoTracksDecorator < Draper::Decorator
  delegate_all

  # Constructor
  # @param tracks [MediaInfo::Tracks] Object containing track information
  def initialize(tracks)
    super(tracks)
  end

  # Delegate to each track attribute, selecting the first value
  # @param name [Symbol] the name of the method
  # @see MediaInfo::Tracks::Attributes
  # @return [Object, nil]
  def method_missing(name, *_args)
    attributes.map { |attrib| attrib.send(name) }.compact.first
  end

  private

    # Retrieve the MediaInfo::Tracks::Attributes for each track type
    # @return [Array<MediaInfo::Tracks::Attributes>]
    def attributes
      @attributes ||= object.track_types.map do |track_type|
        object.send(track_type.to_sym)
      end
    end
end
