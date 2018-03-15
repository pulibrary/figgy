# frozen_string_literal: true
module ThumbnailHelper
  include ::BlacklightHelper

  def build_iiif_thumbnail_path(id, image_options = {})
    url = ManifestBuilder::ManifestHelper.new.manifest_image_thumbnail_path(id)
    image_tag url, image_options.merge(onerror: default_icon_fallback) if url.present?
  rescue
    image_tag 'default.png'
  end

  def default_icon_fallback
    "this.src='#{image_path('default.png')}'"
  end

  def figgy_thumbnail_path(document, image_options = {})
    document = document.try(:resource) || document
    value = send(plum_thumbnail_method(document), document, image_options)
    value
  end

  def geo_thumbnail?(document)
    parent = document.is_a?(FileSet) ? document.decorate.parent : document
    return false if parent.class.can_have_manifests?
    parent.try(:geo_resource?) ? true : false
  end

  def geo_thumbnail_path(document, image_options = {})
    unless document.is_a?(FileSet)
      file_set_id = Array(document.thumbnail_id).first
      return unless file_set_id
      document = Valkyrie.config.metadata_adapter.query_service.find_by(id: file_set_id)
    end
    thumbnail_id = document.thumbnail_files.first.try(:id)
    return unless thumbnail_id
    url = valhalla.download_path(document.id, thumbnail_id)
    image_tag url, image_options.merge(onerror: default_icon_fallback) if url.present?
  end

  def iiif_thumbnail_path(document, image_options = {})
    return unless document.thumbnail_id
    id = Array(document.thumbnail_id).first
    return build_iiif_thumbnail_path(id, image_options) if id == document.id
    return if id.blank?
    thumbnail_document = Valkyrie.config.metadata_adapter.query_service.find_by(id: id)
    iiif_thumbnail_path(thumbnail_document, image_options)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Valkyrie.logger.warn "Unable to load thumbnail for #{document}"
    nil
  end

  def plum_thumbnail_method(document)
    return :geo_thumbnail_path if geo_thumbnail?(document)
    :iiif_thumbnail_path
  end
end
