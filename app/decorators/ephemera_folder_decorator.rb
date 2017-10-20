# frozen_string_literal: true
class EphemeraFolderDecorator < Valkyrie::ResourceDecorator
  display(
    [
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
      :rendered_rights_statement,
      :series,
      :creator,
      :contributor,
      :publisher,
      :geographic_origin,
      :subject,
      :geo_subject,
      :description,
      :date_created,
      :rendered_date_range,
      :dspace_url,
      :source_url,
      :visibility
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

  def members
    @members ||= query_service.find_members(resource: model).to_a
  end

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
    @ephemera_box ||= parent if parent.is_a?(EphemeraBox)
  end

  def ephemera_project
    @ephemera_project ||= parent.is_a?(EphemeraBox) ? parent.ephemera_project : parent
  end

  def collection_slugs
    @collection_slugs ||= Array.wrap(ephemera_project.try(:slug))
  end

  def parent
    @parent ||= query_service.find_parents(resource: model).to_a.first.try(:decorate)
  end

  def manageable_files?
    true
  end

  def manageable_structure?
    false
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

  # Provide "Category -- Subject" with each linked to faceted search results
  def rendered_subject
    subject.map do |value|
      value = value.decorate if value.is_a? EphemeraTerm
      linked_category = link_to_facet_search(field: 'display_subject_ssim', value: value.vocabulary.label)
      # Don't link to both if they're the same
      if value.label == value.vocabulary.label
        linked_category
      else
        "#{linked_category} -- #{link_to_facet_search(field: 'display_subject_ssim', value: value.label)}".html_safe
      end
    end
  end

  def subject
    super.map { |value| controlled_value_for(value) }
  end

  def categories
    subject.map do |value|
      value = value.decorate if value.is_a? EphemeraTerm
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

    def link_to_facet_search(field:, value:)
      # I'm not sure why we can't use catalog_path. but root_path is essentially the same
      query = { "f[#{field}][]" => value }.to_param
      h.link_to value, "#{h.root_path}?#{query}"
    end
end
