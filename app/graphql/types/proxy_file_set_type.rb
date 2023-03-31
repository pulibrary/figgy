# frozen_string_literal: true
class Types::ProxyFileSetType < Types::BaseObject
  implements Types::Resource
  def viewing_hint; end

  def label
    object.label.try(:first)
  end

  # Audio files which we plan to proxy (ones which are in Playlists) don't have
  # thumbnails, so this has to return blank. The order manager will load, but
  # will throw console errors.
  def thumbnail
    {
      id: object.id.to_s,
      thumbnail_url: "",
      iiif_service_url: ""
    }
  end

  def source_metadata_identifier; end

  def members
    []
  end
end
