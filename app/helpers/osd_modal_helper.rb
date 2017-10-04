# frozen_string_literal: true
module OsdModalHelper
  include ::BlacklightHelper
  def osd_modal_for(resource, &block)
    if !resource
      yield
    else
      content_tag :span, class: 'ignore-select', data: { modal_manifest: "#{ManifestBuilder::ManifestHelper.new.manifest_image_path(resource)}/info.json" }, &block
    end
  rescue
    content_tag :span
  end

  def default_icon_fallback
    "this.src='#{image_path('default.png')}'"
  end

  def figgy_thumbnail_path(document, image_options = {})
    document = document.try(:resource) || document
    value = send(plum_thumbnail_method(document), document, image_options)
    value
  end

  def plum_thumbnail_method(_document)
    :iiif_thumbnail_path
  end

  def iiif_thumbnail_path(document, image_options = {})
    return unless document.thumbnail_id
    id = Array(document.thumbnail_id).first
    return build_thumbnail_path(id, image_options) if id == document.id
    return if id.blank?
    thumbnail_document = Valkyrie.config.metadata_adapter.query_service.find_by(id: id)
    iiif_thumbnail_path(thumbnail_document, image_options)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Valkyrie.logger.warn "Unable to load thumbnail for #{document}"
    nil
  end

  def build_thumbnail_path(id, image_options = {})
    url = ManifestBuilder::ManifestHelper.new.manifest_image_thumbnail_path(id)
    image_tag url, image_options.merge(onerror: default_icon_fallback) if url.present?
  rescue
    image_tag 'default.png'
  end
end
