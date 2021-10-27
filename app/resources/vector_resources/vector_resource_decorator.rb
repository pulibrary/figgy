# frozen_string_literal: false
class VectorResourceDecorator < Valkyrie::ResourceDecorator
  display Schema::Geo.attributes, :ark, :rendered_holding_location, :rendered_coverage, :member_of_collections
  suppress :coverage, :identifier, :source_jsonld, :thumbnail_id

  delegate(*Schema::Geo.attributes, to: :primary_imported_metadata, prefix: :imported)

  def attachable_objects
    [VectorResource]
  end

  delegate :members, :parents, :decorated_file_sets, :geo_metadata_members, to: :wayfinder

  # TODO: Rename to geo_vector_members
  def geo_members
    wayfinder.geo_vector_members
  end

  # TODO: Rename to decorated_raster_resource_parents
  def raster_resource_parents
    wayfinder.decorated_raster_resource_parents
  end

  # Use case for nesting vector resources
  #   - time series: e.g., nyc transit system, released every 6 months
  # TODO: Rename to decorated_vector_resources
  def vector_resource_members
    wayfinder.decorated_vector_resources
  end

  # TODO: rename to decorated_vector_resource_parents
  def vector_resource_parents
    wayfinder.decorated_vector_resource_parents
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
    false
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
    decorated_geo_members + vector_resource_members
  end

  def title
    return ["#{super.first} (#{portion_note.first})"] unless portion_note.blank?
    super
  end

  # Overridden because we don't care if the object isn't visible - downloadable
  # takes precedence for vector resources.
  def downloadable?
    return false unless respond_to?(:downloadable)
    return visible? && public_readable_state? if downloadable.nil?

    downloadable&.include?("public")
  end
end
