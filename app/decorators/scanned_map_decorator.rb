# frozen_string_literal: false
class ScannedMapDecorator < Valkyrie::ResourceDecorator
  display Schema::Geo.attributes,
          :ark,
          :rendered_holding_location,
          :rendered_coverage,
          :member_of_collections,
          :relation,
          :rendered_links

  suppress :thumbnail_id,
           :coverage,
           :cartographic_projection,
           :identifier,
           :source_jsonld,
           :sort_title

  display_in_manifest displayed_attributes
  suppress_from_manifest Schema::IIIF.attributes,
                         :visibility,
                         :internal_resource,
                         :rights_statement,
                         :rendered_rights_statement,
                         :thumbnail_id

  delegate(*Schema::Geo.attributes, to: :primary_imported_metadata, prefix: :imported)

  def attachable_objects
    [ScannedMap, RasterResource]
  end

  def collections
    Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_references_by(resource: self, property: :member_of_collection_ids).to_a
  end

  # Display the resource attributes
  # @return [Hash] a Hash of all of the resource attributes
  def display_attributes
    super.reject { |k, v| imported_attributes.fetch(k, nil) == v }
  end

  def file_sets
    @file_sets ||= members.select { |r| r.is_a?(FileSet) }.map(&:decorate).to_a
  end

  def geo_members
    members.select do |member|
      next unless member.respond_to?(:mime_type)
      ControlledVocabulary.for(:geo_image_format).include?(member.mime_type.first)
    end
  end

  def geo_metadata_members
    members.select do |member|
      next unless member.respond_to?(:mime_type)
      ControlledVocabulary.for(:geo_metadata_format).include?(member.mime_type.first)
    end
  end

  def human_readable_type
    return I18n.translate("models.map_set", default: "Map Set") if map_set?
    model.human_readable_type
  end

  # Access the resources attributes exposed for the IIIF Manifest metadata
  # @return [Hash] a Hash of all of the resource attributes
  def iiif_manifest_attributes
    super.merge imported_attributes
  end

  def imported_attribute(attribute_key)
    return primary_imported_metadata.send(attribute_key) if primary_imported_metadata.try(attribute_key)
    Array.wrap(primary_imported_metadata.attributes.fetch(attribute_key, []))
  end

  # Access the resource attributes imported from an external service
  # @return [Hash] a Hash of all of the resource attributes
  def imported_attributes
    @imported_attributes ||= ImportedAttributes.new(subject: self, keys: self.class.displayed_attributes).to_h
  end

  def imported_language
    imported_attribute(:language).map do |language|
      ControlledVocabulary.for(:language).find(language).label
    end
  end
  alias display_imported_language imported_language

  def language
    (super || []).map do |language|
      ControlledVocabulary.for(:language).find(language).label
    end
  end

  def manageable_structure?
    true
  end

  def map_set?
    !scanned_map_members.empty?
  end

  def members
    @members ||= query_service.find_members(resource: model).to_a
  end

  def raster_resource_members
    @raster_resources ||= members.select { |r| r.is_a?(RasterResource) }.map(&:decorate).to_a
  end

  def rendered_coverage
    display_coverage = coverage || imported_metadata.try(:first).try(:coverage)
    h.bbox_display(display_coverage)
  end

  def rendered_holding_location
    value = holding_location
    return unless value.present?
    vocabulary = ControlledVocabulary.for(:holding_location)
    value.map do |holding_location|
      vocabulary.find(holding_location).label
    end
  end

  def rendered_links
    return unless references
    refs = JSON.parse(references.first)
    refs.delete("iiif_manifest_paths")
    refs.map do |url, _label|
      h.link_to(url, url)
    end
  end

  def rendered_rights_statement
    rights_statement.map do |rights_statement|
      term = ControlledVocabulary.for(:rights_statement).find(rights_statement)
      next unless term
      h.link_to(term.label, term.value) +
        h.content_tag("br") +
        h.content_tag("p") do
          term.definition.html_safe
        end +
        h.content_tag("p") do
          I18n.t("works.show.attributes.rights_statement.boilerplate").html_safe
        end
    end
  end

  def scanned_map_members
    @scanned_maps ||= members.select { |r| r.is_a?(ScannedMap) }.map(&:decorate).to_a
  end

  def scanned_map_parents
    @scanned_map_parents ||= parents.select { |r| r.is_a?(ScannedMap) }.map(&:decorate).to_a
  end

  def title
    return "#{super.first} (#{portion_note.first})" if portion_note
    super
  end
end
