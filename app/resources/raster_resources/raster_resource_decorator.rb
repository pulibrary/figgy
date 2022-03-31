# frozen_string_literal: false
class RasterResourceDecorator < Valkyrie::ResourceDecorator
  display Schema::Geo.attributes, :ark, :rendered_holding_location, :rendered_coverage, :member_of_collections
  suppress :coverage, :identifier, :source_jsonld, :thumbnail_id
  delegate(*Schema::Geo.attributes, to: :primary_imported_metadata, prefix: :imported)

  def attachable_objects
    [RasterResource, VectorResource]
  end

  delegate :decorated_file_sets,
           :decorated_raster_resources,
           :decorated_raster_resource_parents,
           :decorated_scanned_map_parents,
           :decorated_vector_resources,
           :geo_members,
           :geo_metadata_members,
           :members,
           :parents,
           :mosaic_file_count,
           :raster_resources_count,
           to: :wayfinder

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
    false
  end

  def coverage
    Array.wrap(super).first ||
      coverage_from_file_set ||
      imported_metadata.try(:first).try(:coverage) ||
      coverage_from_parent
  end

  def coverage_from_parent
    parent = parents.first
    return unless parent
    parent.decorate.coverage
  end

  def coverage_from_file_set
    bounds = geo_members&.first&.bounds&.first
    return unless bounds
    GeoCoverage.new(bounds[:north], bounds[:east], bounds[:south], bounds[:west]).to_s
  end

  def rendered_coverage
    h.bbox_display(coverage)
  end

  def rendered_holding_location
    value = holding_location
    return if value.blank?
    vocabulary = ControlledVocabulary.for(:holding_location)
    value.map do |holding_location|
      vocabulary.find(holding_location).label
    end
  end

  def rendered_rights_statement
    rights_statement.map do |rights_statement|
      term = ControlledVocabulary.for(:rights_statement).find(rights_statement)
      next unless term
      h.link_to(term.label, term.value) +
        h.tag.br +
        h.tag.p do
          term.definition.html_safe
        end +
        h.tag.p do
          I18n.t("works.show.attributes.rights_statement.boilerplate").html_safe
        end
    end
  end

  def thumbnail_members
    decorated_geo_members = geo_members.map(&:decorate)
    decorated_geo_members + decorated_raster_resources + decorated_vector_resources
  end

  def title
    return ["#{super.first} (#{portion_note.first})"] if portion_note.present?
    super
  end

  def human_readable_type
    if model.id.present? && wayfinder.raster_resources_count.positive?
      I18n.translate("models.raster_set", default: "Raster Set")
    else
      model.human_readable_type
    end
  end
end
