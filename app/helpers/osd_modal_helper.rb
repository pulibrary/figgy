# frozen_string_literal: true
module OsdModalHelper
  include ::BlacklightHelper
  def osd_modal_for(id, &block)
    if !id
      yield
    else
      content_tag :span, class: 'ignore-select', data: { modal_manifest: "#{ManifestBuilder::ManifestHelper.new.manifest_image_path(id)}/info.json" }, &block
    end
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
    thumbnail_document = Valkyrie.config.metadata_adapter.query_service.find_by(id: id)
    return iiif_thumbnail_path(thumbnail_document, image_options) if thumbnail_document.try(:thumbnail_id)
    url = ManifestBuilder::ManifestHelper.new.manifest_image_thumbnail_path(thumbnail_document.id)
    image_tag url, image_options.merge(onerror: default_icon_fallback) if url.present?
  end
end
