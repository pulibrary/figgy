# frozen_string_literal: false
class VectorResourceDecorator < Valhalla::ResourceDecorator
  display Schema::Geo.attributes, :rendered_holding_location, :rendered_coverage, :member_of_collections
  suppress :thumbnail_id, :coverage, :source_jsonld

  delegate(*Schema::Geo.attributes, to: :primary_imported_metadata, prefix: :imported)

  def attachable_objects
    [VectorResource]
  end

  def file_sets
    @file_sets ||= members.select { |r| r.is_a?(FileSet) }.map(&:decorate).to_a
  end

  def geo_members
    members.select do |member|
      next unless member.respond_to?(:mime_type)
      ControlledVocabulary.for(:geo_vector_format).include?(member.mime_type.first)
    end
  end

  def geo_metadata_members
    members.select do |member|
      next unless member.respond_to?(:mime_type)
      ControlledVocabulary.for(:geo_metadata_format).include?(member.mime_type.first)
    end
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

  def members
    @members ||= query_service.find_members(resource: model).to_a
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
          I18n.t("valhalla.works.show.attributes.rights_statement.boilerplate").html_safe
        end
    end
  end

  # Use case for nesting vector resources
  #   - time series: e.g., nyc transit system, released every 6 months
  def vector_resource_members
    @vector_resources ||= members.select { |r| r.is_a?(VectorResource) }.map(&:decorate).to_a
  end
end
