# frozen_string_literal: true
class ScannedResourceDecorator < Valkyrie::ResourceDecorator
  self.display_attributes += Schema::Common.attributes + imported_attributes(Schema::Common.attributes) + [:member_of_collections, :rendered_holding_location] - [:thumbnail_id]
  self.iiif_manifest_attributes = display_attributes + [:title] - \
                                  imported_attributes(Schema::Common.attributes) - \
                                  Schema::IIIF.attributes - [:visibility, :internal_resource, :rights_statement, :rendered_rights_statement, :thumbnail_id]
  delegate :query_service, to: :metadata_adapter
  delegate(*Schema::Common.attributes, to: :primary_imported_metadata, prefix: :imported)

  def member_of_collections
    @member_of_collections ||=
      begin
        query_service.find_references_by(resource: model, property: :member_of_collection_ids)
                     .map(&:decorate)
                     .map(&:title).to_a
      end
  end

  def members
    @members ||= query_service.find_members(resource: model)
  end

  def volumes
    @volumes ||= members.select { |r| r.is_a?(ScannedResource) }.map(&:decorate).to_a
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
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

  def iiif_manifest_attributes
    current_attributes = attributes(self.class.iiif_manifest_attributes)
    imported_attributes = attributes(self.class.imported_attributes(Schema::Common.attributes))

    imported_attributes.each_pair do |imported_key, value|
      key = imported_key.to_s.sub(/imported_/, '').to_sym
      if current_attributes.key?(key) && value.present?
        current_attributes[key].concat(value)
      end
    end

    current_attributes
  end

  def parents
    Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_references_by(resource: self, property: :member_of_collection_ids).to_a
  end
  alias collections parents
end
