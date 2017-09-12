# frozen_string_literal: true
class EphemeraFolderDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [
    :barcode,
    :folder_number,
    :title,
    :sort_title,
    :alternative_title,
    :language,
    :genre,
    :width,
    :height,
    :page_count,
    :rights_statement,
    :series,
    :creator,
    :contributor,
    :publisher,
    :geographic_origin,
    :subject,
    :geo_subject,
    :description,
    :date_created,
    :dspace_url,
    :source_url,
    :thumbnail_id,
    :visibility
  ]
  self.iiif_manifest_attributes = display_attributes + [:title] - \
                                  imported_attributes(Schema::Common.attributes) - \
                                  Schema::IIIF.attributes - [:visibility, :internal_resource, :rights_statement, :rendered_rights_statement, :thumbnail_id]

  delegate :query_service, to: :metadata_adapter

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

  def manageable_files?
    true
  end

  def manageable_structure?
    true
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
end
