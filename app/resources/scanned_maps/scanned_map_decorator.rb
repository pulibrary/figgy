# frozen_string_literal: false
class ScannedMapDecorator < Valkyrie::ResourceDecorator
  display Schema::Geo.attributes,
          :ark,
          :gbl_suppressed_override,
          :rendered_holding_location,
          :rendered_coverage,
          :member_of_collections,
          :relation,
          :rendered_links

  suppress :thumbnail_id,
           :coverage,
           :cartographic_projection,
           :extent,
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

  delegate :collections, :geo_metadata_members, :members, :parents, to: :wayfinder

  def collection_slugs
    @collection_slugs ||= collections.flat_map(&:slug)
  end

  # TODO: Rename to decorated_file_sets
  def file_sets
    wayfinder.decorated_file_sets
  end

  # TODO: Rename to geo_image_members
  def geo_members
    wayfinder.geo_image_members
  end

  # TODO: Rename to decorated_raster_resources
  def raster_resource_members
    wayfinder.decorated_raster_resources
  end

  # TODO: Rename to decorated_scanned_maps
  def scanned_map_members
    wayfinder.decorated_scanned_maps
  end

  # TODO: Rename to decorated_scanned_map_parents
  def scanned_map_parents
    wayfinder.decorated_scanned_map_parents
  end

  # Display the resource attributes
  # @return [Hash] a Hash of all of the resource attributes
  def display_attributes
    super.reject { |k, v| imported_attributes.fetch(k, nil) == v }
  end

  def gbl_suppressed_override
    super ? "True" : "False"
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

  def rendered_coverage
    display_coverage = Array.wrap(coverage).first || imported_metadata.try(:first).try(:coverage)
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

  def thumbnail_members
    decorated_geo_members = geo_members.map(&:decorate)
    decorated_geo_members + scanned_map_members
  end

  def title
    return ["#{super.first} (#{portion_note.first})"] unless portion_note.blank?
    super
  end
end
