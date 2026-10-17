module ThumbnailHelper
  include ::BlacklightHelper

  def default_path
    image_tag "default.png", class: "thumbnail-inner"
  end

  def build_iiif_thumbnail_path(document, image_options = {})
    url = iiif_thumbnail_url(document)
    image_tag url, image_options.merge(onerror: "this.remove()") if url.present?
  rescue
    default_path
  end

  def default_icon_fallback
    "this.src='#{image_path('default.png')}'"
  end

  # Generate the thumbnail path for a given SolrDocument
  # @param document [SolrDocument]
  # @param image_options [Hash]
  # @return [String]
  def figgy_thumbnail_path(document, image_options = {})
    document = thumbnail_document(document)
    value = send(figgy_thumbnail_method(document), document, image_options)
    value
  rescue TypeError # Error raised by the QueryService in iiif_thumbnail_path
    Rails.logger.error("Unable to retrieve the resource with the ID #{document.id}")
    default_icon_fallback
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Honeybadger.notify("Unable to retrieve the resource with the ID #{document.id} - probably a record in Solr but not in the database")
  end

  # Generate the thumbnail image URL for a given resource
  # @param document [SolrDocument, Valkyrie::Resource]
  # @return [String, nil]
  def figgy_thumbnail_url(document)
    document = thumbnail_document(document)
    if geo_thumbnail?(document)
      file_set = geo_thumbnail_file_set(document)
      geo_thumbnail_url(file_set) if file_set
    else
      file_set = iiif_thumbnail_file_set(document)
      iiif_thumbnail_url(file_set) if file_set
    end
  end

  def thumbnail_document(document)
    document.try(:resource) || document.try(:model) || document
  end

  def geo_thumbnail?(document)
    parent = document.is_a?(FileSet) ? document.decorate.parent : document
    return false unless parent
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

  def geo_thumbnail_file_set(document)
    document.is_a?(FileSet) ? document : geo_file_set(document)
  end

  def geo_thumbnail_path(document, image_options = {})
    file_set = geo_thumbnail_file_set(document)
    return default_path if file_set.nil?
    build_geo_thumbnail_path(file_set, image_options)
  end

  def build_geo_thumbnail_path(document, image_options = {})
    url = geo_thumbnail_url(document)
    return default_path if url.blank?

    image_tag url, image_options.merge(onerror: default_icon_fallback)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    default_path
  end

  def geo_thumbnail_url(file_set)
    return unless file_set.pyramidal_derivative
    ManifestBuilder::ManifestHelper.new.manifest_image_thumbnail_path(file_set, format: "png")
  end

  def iiif_thumbnail_path(document, image_options = {})
    file_set = iiif_thumbnail_file_set(document)
    build_iiif_thumbnail_path(file_set, image_options) if file_set
  end

  def iiif_thumbnail_file_set(document)
    if document.thumbnail_id.blank?
      return unless document.respond_to?(:member_ids)

      document.member_ids.each do |member_id|
        member = Valkyrie.config.metadata_adapter.query_service.find_by(id: member_id)
        return iiif_thumbnail_file_set(member) if member.respond_to?(:thumbnail_id) && member.thumbnail_id
      end

      return nil
    end

    id = Array(document.thumbnail_id).first
    return document if id == document.id
    return if id.blank?
    thumbnail_document = Valkyrie.config.metadata_adapter.query_service.find_by(id: id)
    iiif_thumbnail_file_set(thumbnail_document)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Valkyrie.logger.warn "Unable to load thumbnail for #{document}"
    nil
  end

  def iiif_thumbnail_url(file_set)
    ManifestBuilder::ManifestHelper.new.manifest_image_thumbnail_path(file_set)
  end

  def figgy_thumbnail_method(document)
    return :geo_thumbnail_path if geo_thumbnail?(document)
    :iiif_thumbnail_path
  end
end
