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
    :categories,
    :geo_subject,
    :description,
    :date_created,
    :rendered_date_range,
    :dspace_url,
    :source_url,
    :visibility,
    :rendered_rights_statement
  ]
  self.iiif_manifest_attributes = display_attributes + [:title] - \
                                  imported_attributes(Schema::Common.attributes) - \
                                  Schema::IIIF.attributes - [:visibility, :internal_resource, :rights_statement, :rendered_rights_statement, :thumbnail_id]

  def collections
    @collections ||= query_service.find_references_by(resource: self, property: :member_of_collection_ids).to_a.map(&:decorate)
  end

  def rendered_date_range
    return unless first_range.present?
    first_range.range_string
  end

  def first_range
    @first_range ||= Array.wrap(date_range).map(&:decorate).first
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

  def ephemera_box
    @ephemera_box ||= query_service.find_parents(resource: model).to_a.first.try(:decorate)
  end

  def ephemera_project
    @ephemera_project ||= ephemera_box.ephemera_project
  end

  def manageable_files?
    true
  end

  def manageable_structure?
    false
  end

  def iiif_manifest_attributes
    local_attributes(self.class.iiif_manifest_attributes)
  end

  def folder_number
    super.first
  end

  def barcode
    super.first
  end

  def rendered_state
    ControlledVocabulary.for(:state_folder_workflow).badge(state)
  end

  def state
    super.first
  end

  def genre
    return super if super.blank?
    controlled_value_for(super.first)
  end

  def geo_subject
    super.map { |value| controlled_value_for(value) }
  end

  def geographic_origin
    return super if super.blank?
    controlled_value_for(super.first)
  end

  def language
    super.map { |value| controlled_value_for(value) }
  end

  def subject
    super.map { |value| controlled_value_for(value) }
  end

  def categories
    subject.map do |value|
      next unless value.is_a? EphemeraTermDecorator
      value.vocabulary
    end.reject(&:nil?)
  end

  private

    def find_resource(resource_id)
      query_service.find_by(id: resource_id).decorate
    rescue Valkyrie::Persistence::ObjectNotFoundError
      Rails.logger.warn "Failed to find the resource #{resource_id}"
      resource_id
    end

    def controlled_value_for(value)
      value.present? && value.is_a?(Valkyrie::ID) ? find_resource(value) : value
    end
end
