# frozen_string_literal: true

module ThumbnailHelper
  include ::BlacklightHelper

  def default_path
    image_tag "default.png", class: "thumbnail-inner"
  end

  def build_iiif_thumbnail_path(document, image_options = {})
    url = ManifestBuilder::ManifestHelper.new.manifest_image_thumbnail_path(document)
    image_tag url, image_options.merge(onerror: "this.remove()") if url.present?
  rescue
    default_path
  end

  def default_icon_fallback
    "this.src='#{image_path("default.png")}'"
  end

  # Generate the thumbnail path for a given SolrDocument
  # @param document [SolrDocument]
  # @param image_options [Hash]
  # @return [String]
  def figgy_thumbnail_path(document, image_options = {})
    document = document.try(:resource) || document.try(:model) || document
    send(figgy_thumbnail_method(document), document, image_options)
  rescue TypeError # This error is raised by the QueryService
    Rails.logger.error("Unable to retrieve the resource with the ID #{document.id}")
    default_icon_fallback
  end

  def geo_thumbnail?(document)
    parent = document.is_a?(FileSet) ? document.decorate.parent : document
    return false if parent.class.can_have_manifests?
    parent.try(:geo_resource?) ? true : false
  end

  def geo_file_set(resource)
    return unless resource.thumbnail_id
    id = Array(resource.thumbnail_id).first
    child = Valkyrie.config.metadata_adapter.query_service.find_by(id: id)
    return child if child.is_a? FileSet
    geo_file_set child
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Valkyrie.logger.warn "Unable to load thumbnail for #{resource}"
    nil
  end

  def geo_thumbnail_path(document, image_options = {})
    return build_geo_thumbnail_path(document, image_options) if document.is_a?(FileSet)
    file_set = geo_file_set document
    return default_path if file_set.nil?
    build_geo_thumbnail_path(file_set, image_options)
  end

  def build_geo_thumbnail_path(document, image_options = {})
    thumbnail_id = document.thumbnail_files.first.try :id
    return default_path unless thumbnail_id

    url = download_path document.id, thumbnail_id
    return default_path unless url.present?

    image_tag url, image_options.merge(onerror: default_icon_fallback)
  end

  def iiif_thumbnail_path(document, image_options = {})
    if document.thumbnail_id.blank?
      return unless document.respond_to?(:member_ids)

      document.member_ids.each do |member_id|
        member = Valkyrie.config.metadata_adapter.query_service.find_by(id: member_id)
        return iiif_thumbnail_path(member, image_options) if member.respond_to?(:thumbnail_id) && member.thumbnail_id
      end

      return nil
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    id = Array(document.thumbnail_id).first
    return build_iiif_thumbnail_path(document, image_options) if id == document.id
    return if id.blank?
    thumbnail_document = Valkyrie.config.metadata_adapter.query_service.find_by(id: id)
    iiif_thumbnail_path(thumbnail_document, image_options)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Valkyrie.logger.warn "Unable to load thumbnail for #{document}"
    nil
  end

  def figgy_thumbnail_method(document)
    return :geo_thumbnail_path if geo_thumbnail?(document)
    :iiif_thumbnail_path
  end
end
