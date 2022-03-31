# frozen_string_literal: false
class VectorResourceDecorator < Valkyrie::ResourceDecorator
  display Schema::Geo.attributes, :ark, :rendered_holding_location, :rendered_coverage, :member_of_collections
  suppress :coverage, :identifier, :source_jsonld, :thumbnail_id

  delegate(*Schema::Geo.attributes, to: :primary_imported_metadata, prefix: :imported)

  def attachable_objects
    [VectorResource]
  end

  delegate :decorated_file_sets,
           :decorated_raster_resource_parents,
           :decorated_vector_resources,
           :decorated_vector_resource_parents,
           :geo_members,
           :geo_metadata_members,
           :members,
           :parents,
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
      imported_metadata.try(:first).try(:coverage) ||
      coverage_from_parent
  end

  def coverage_from_parent
    parent = parents.first
    return unless parent
    parent.decorate.coverage
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
    decorated_geo_members + decorated_vector_resources
  end

  def title
    return ["#{super.first} (#{portion_note.first})"] if portion_note.present?
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
