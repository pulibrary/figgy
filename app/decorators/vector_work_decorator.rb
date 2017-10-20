# frozen_string_literal: false
class VectorWorkDecorator < Valkyrie::ResourceDecorator
  display(Schema::Geo.attributes)
  display(
    [
      :rendered_coverage,
      :member_of_collections
    ]
  )
  suppress(
    [
      :thumbnail_id,
      :coverage
    ]
  )

  def members
    @members ||= query_service.find_members(resource: model).to_a
  end

  # Use case for nesting vector works
  #   - time series: e.g., nyc transit system, released every 6 months
  def vector_work_members
    @vector_works ||= members.select { |r| r.is_a?(VectorWork) }.map(&:decorate).to_a
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
    false
  end

  def attachable_objects
    [VectorWork]
  end
end
