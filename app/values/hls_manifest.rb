# frozen_string_literal: true
class HlsManifest
  def self.for(file_set:, file_metadata:, auth_token: nil)
    if file_metadata.mime_type.first.to_s == "application/x-mpegURL"
      new(file_set: file_set, file_metadata: file_metadata, auth_token: auth_token)
    end
  end

  attr_reader :file_set, :file_metadata, :auth_token
  delegate :to_s, to: :playlist

  def initialize(file_set:, file_metadata:, auth_token:)
    @file_set = file_set
    @file_metadata = file_metadata
    @auth_token = auth_token
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
