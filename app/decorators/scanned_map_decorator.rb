# frozen_string_literal: false
class ScannedMapDecorator < Valkyrie::ResourceDecorator
  self.display_attributes += Schema::Geo.attributes + [:rendered_coverage, :member_of_collections] - [:thumbnail_id, :coverage, :cartographic_projection]
  self.iiif_manifest_attributes = display_attributes + [:title] - \
                                  Schema::IIIF.attributes - [:visibility, :internal_resource, :rights_statement, :rendered_rights_statement, :thumbnail_id]

  def members
    @members ||= query_service.find_members(resource: model)
  end

  def scanned_map_members
    return [] if members.nil?
    @scanned_maps ||= members.select { |r| r.is_a?(ScannedMap) }.map(&:decorate).to_a
  end

  def geo_members
    return [] if members.nil?
    members.select do |member|
      next unless member.respond_to?(:mime_type)
      ControlledVocabulary.for(:geo_image_format).include?(member.mime_type.first)
    end
  end

  def geo_metadata_members
    return [] if members.nil?
    members.select do |member|
      next unless member.respond_to?(:mime_type)
      ControlledVocabulary.for(:geo_metadata_format).include?(member.mime_type.first)
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

  def rendered_coverage
    h.bbox_display(coverage)
  end

  def manageable_structure?
    true
  end

  def attachable_objects
    [ScannedMap]
  end

  def iiif_manifest_attributes
    local_attributes(self.class.iiif_manifest_attributes)
  end
end
