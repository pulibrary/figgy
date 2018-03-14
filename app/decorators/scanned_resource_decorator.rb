# frozen_string_literal: true
class ScannedResourceDecorator < Valkyrie::ResourceDecorator
  display(Schema::Common.attributes)
  display(
    [
      :rendered_holding_location,
      :member_of_collections
    ]
  )
  suppress(
    [
      :thumbnail_id,
      :imported_author,
      :source_jsonld,
      :source_metadata,
      :sort_title
    ]
  )
  iiif_manifest_display(displayed_attributes)
  iiif_manifest_suppress(Schema::IIIF.attributes)
  iiif_manifest_suppress(
    [
      :visibility,
      :internal_resource,
      :rights_statement,
      :rendered_rights_statement,
      :thumbnail_id
    ]
  )

  delegate(*Schema::Common.attributes, to: :primary_imported_metadata, prefix: :imported)

  def members
    @members ||= query_service.find_members(resource: model).to_a
  end

  def volumes
    @volumes ||= members.select { |r| r.is_a?(ScannedResource) }.map(&:decorate).to_a
  end

  def file_sets
    @file_sets ||= members.select { |r| r.is_a?(FileSet) }.map(&:decorate).to_a
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

  def rendered_holding_location
    value = holding_location
    return unless value.present?
    vocabulary = ControlledVocabulary.for(:holding_location)
    value.map do |holding_location|
      vocabulary.find(holding_location).label
    end
  end

  def manageable_structure?
    true
  end

  def attachable_objects
    [ScannedResource]
  end

  # Access the resource attributes imported from an external service
  # @return [Hash] a Hash of all of the resource attributes
  def imported_attributes
    @imported_attributes ||= ImportedAttributes.new(subject: self, keys: self.class.displayed_attributes).to_h
  end

  # Display the resource attributes
  # @return [Hash] a Hash of all of the resource attributes
  def display_attributes
    super.reject { |k, v| imported_attributes.fetch(k, nil) == v }
  end

  # Access the resources attributes exposed for the IIIF Manifest metadata
  # @return [Hash] a Hash of all of the resource attributes
  def iiif_manifest_attributes
    super.merge imported_attributes
  end

  def parents
    Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_references_by(resource: self, property: :member_of_collection_ids).to_a
  end
  alias collections parents

  def decorated_parent_resource
    @decorated_parent_resource ||= Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_parents(resource: self).first.try(:decorate)
  end

  def collection_slugs
    @collection_slugs ||= collections.flat_map(&:slug)
  end

  def human_readable_type
    return model.human_readable_type if volumes.empty?
    I18n.translate("valhalla.models.multi_volume_work", default: 'Multi Volume Work')
  end

  def imported_attribute(attribute_key)
    return primary_imported_metadata.send(attribute_key) if primary_imported_metadata.try(attribute_key)
    Array.wrap(primary_imported_metadata.attributes.fetch(attribute_key, []))
  end

  def imported_language
    imported_attribute(:language).map do |language|
      ControlledVocabulary.for(:language).find(language).label
    end
  end
  alias display_imported_language imported_language

  def created
    output = super
    return if output.blank?
    output.map { |value| Date.parse(value.to_s).strftime("%B %-d, %Y") }
  end

  def imported_created
    output = imported_attribute(:created)
    return if output.blank?
    output.map { |value| Date.parse(value.to_s).strftime("%B %-d, %Y") }
  end
end
