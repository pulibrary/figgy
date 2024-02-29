# frozen_string_literal: true
class HlsManifest::Caption
  # Creates an HLS manifest for the caption VTT file given in file_metadata.
  attr_reader :file_set, :file_metadata, :auth_token
  delegate :to_s, to: :playlist

  def initialize(file_set:, file_metadata:, auth_token:)
    @file_set = file_set
    @file_metadata = file_metadata
    @auth_token = auth_token
    attach_caption
  end

  def playlist
    @playlist ||= M3u8::Playlist.new(
      target: duration,
      version: 3,
      sequence: 0
    )
  end

  # Length of the AV track in seconds - add an extra second so it rounds up.
  def duration
    @duration ||= file_set.primary_file.duration.first.to_i + 1
  end

  def attach_caption
    playlist.items << M3u8::SegmentItem.new(
      duration: duration,
      segment: helper.download_path(file_set.id, file_metadata.id, auth_token: auth_token)
    )
  end

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end
end
