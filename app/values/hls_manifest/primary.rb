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
    attach_captions
    attach_av_track
  end

  def playlist
    @playlist ||= M3u8::Playlist.new(version: 4, independent_segments: true)
  end

  def attach_av_track
    playlist.items << M3u8::PlaylistItem.new(
      profile: "high",
      subtitles: subtitles,
      bandwidth: 5400,
      width: width,
      height: height,
      uri: helper.download_url(file_set.id, file_metadata.id, auth_token: auth_token, format: "m3u8")
    )
  end

  def width
    file_set.primary_file&.width&.first.presence&.to_i
  end

  def height
    file_set.primary_file&.height&.first.presence&.to_i
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
        uri: helper.download_url(file_set.id, caption_metadata.id, as: "stream", auth_token: auth_token, format: "m3u8")
      )
    end
  end

  def caption_language(caption_metadata)
    iso_codes = caption_metadata.caption_language

    return language_tag(iso_codes.first) if iso_codes.count == 1
    nil
  end

  # HLS requires two letter language tags
  # If a code has no two letter form, then use the the three letter tag
  def language_tag(iso_code)
    ISO_639.find(iso_code)&.alpha2.presence || iso_code
  end

  # Says via HLS that the subtitles should be treated as captions in HLS.
  def accessibility_characteristics
    "public.accessibility.transcribes-spoken-dialog,public.accessibility.describes-music-and-sound"
  end

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end

  def subtitles
    "subs" if file_set.captions.count > 0
  end
end
