# frozen_string_literal: true
# Class responsible for converting an HLS manifest (.m3u8) file from ffmpeg to
# include an auth token in its file references, if appropriate.
class HlsManifest
  # Factory method for returning the different kinds of manifests. If asked for
  # a "stream" then it generates a manifest dynamically, otherwise it simply
  # returns the manifest referenced by file_metadata, mutated if needed.
  # @return [#to_s] Object whose #to_s method returns an HLS Manifest.
  def self.for(file_set:, file_metadata:, as: nil, auth_token: nil)
    return unless file_metadata.hls_manifest?
    if as == "stream"
      Primary.new(file_set: file_set, file_metadata: file_metadata, auth_token: auth_token)
    else
      new(file_set: file_set, file_metadata: file_metadata, auth_token: auth_token)
    end
  end

  attr_reader :file_set, :file_metadata, :auth_token
  delegate :to_s, to: :playlist

  def initialize(file_set:, file_metadata:, auth_token:)
    @file_set = file_set
    @file_metadata = file_metadata
    @auth_token = auth_token
    playlist.target = file_set.primary_file.duration.first.to_i + 1
    apply_auth_token if auth_token.present?
  end

  def apply_auth_token
    playlist.items.each do |item|
      item.segment = "#{item.segment}?auth_token=#{auth_token}"
    end
  end

  def playlist
    @playlist ||= M3u8::Playlist.read(binary_file.io)
  end

  def binary_file
    @binary_file ||= Valkyrie::StorageAdapter.find_by(id: file_metadata.file_identifiers.first)
  end
end
