# frozen_string_literal: true
class ScannedResourceDecorator < Valkyrie::ResourceDecorator
  self.display_attributes += Schema::Common.attributes + Schema::Common.attributes.map { |attrib| ('imported_' + attrib.to_s).to_sym } + [:member_of_collections, :rendered_holding_location]
  delegate :query_service, to: :metadata_adapter
  delegate(*Schema::Common.attributes, to: :primary_imported_metadata, prefix: :imported)

  def member_of_collections
    @member_of_collections ||=
      begin
        member_of_collection_ids.map do |id|
          query_service.find_by(id: id).decorate
        end.map(&:title)
      end
  end

  def member_of_collection_ids
    super || []
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
end
