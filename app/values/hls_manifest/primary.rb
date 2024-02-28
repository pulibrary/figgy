# frozen_string_literal: true
class HlsManifest::Primary
  # Primary HLS manifests include the video HLS manifest as well as any caption
  # manifests. In the future it would also allow us to attach streams at
  # different qualities, or multiple kinds of captions/subtitles.
  attr_reader :file_set, :file_metadata, :auth_token
  delegate :to_s, to: :playlist

  def initialize(file_set:, file_metadata:, auth_token:)
    @file_set = file_set
    @file_metadata = file_metadata
    @auth_token = auth_token
    attach_av_track
  end

  def playlist
    @playlist ||= M3u8::Playlist.new
  end

  def attach_av_track
    playlist.items << M3u8::PlaylistItem.new(
      profile: "high",
      subtitles: "subs",
      bandwidth: 540,
      uri: helper.download_path(file_set.id, file_metadata.id, auth_token: auth_token)
    )
  end

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end
end
