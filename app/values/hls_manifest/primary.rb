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
    attach_captions
  end

  def playlist
    @playlist ||= M3u8::Playlist.new
  end

  def attach_av_track
    playlist.items << M3u8::PlaylistItem.new(
      profile: "high",
      subtitles: "subs",
      bandwidth: 540,
      uri: helper.download_path(file_set.id, file_metadata.id, auth_token: auth_token, format: "m3u8")
    )
  end

  def attach_captions
    file_set.captions.each do |caption_metadata|
      playlist.items << M3u8::MediaItem.new(
        type: "SUBTITLES",
        group_id: "subs",
        name: caption_metadata.caption_language_label,
        default: caption_metadata.original_language_caption,
        autoselect: true,
        characteristics: accessibility_characteristics,
        language: caption_language(caption_metadata),
        uri: helper.download_path(file_set.id, caption_metadata.id, as: "stream", auth_token: auth_token, format: "m3u8")
      )
    end
  end

  def caption_language(caption_metadata)
    iso_codes = caption_metadata.caption_language

    return iso_codes.first if iso_codes.count == 1
    nil
  end

  # Says via HLS that the subtitles should be treated as captions in HLS.
  def accessibility_characteristics
    "public.accessibility.describes-spoken-dialog,public.accessibility.describes-music-and-sound"
  end

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end
end
