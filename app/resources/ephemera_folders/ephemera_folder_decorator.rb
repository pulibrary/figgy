# frozen_string_literal: true
class EphemeraFolderDecorator < Valkyrie::ResourceDecorator
  display :barcode,
          :folder_number,
          :title,
          :sort_title,
          :alternative_title,
          :transliterated_title,
          :language,
          :genre,
          :width,
          :height,
          :page_count,
          :keywords,
          :rights_statement,
          :series,
          :creator,
          :contributor,
          :publisher,
          :geographic_origin,
          :rendered_subject,
          :geo_subject,
          :description,
          :date_created,
          :rendered_date_range,
          :local_identifier,
          :provenance,
          :dspace_url,
          :source_url,
          :visibility,
          :rendered_rights_statement,
          :rendered_ocr_language,
          :rendered_holding_location,
          :member_of_collections

  display_in_manifest displayed_attributes, :subject, :categories
  suppress_from_manifest Schema::IIIF.attributes,
                         :visibility,
                         :internal_resource,
                         :rights_statement,
                         :rendered_rights_statement,
                         :rendered_ocr_language,
                         :thumbnail_id,
                         :rendered_date_range,
                         :rendered_subject,
                         :created_at,
                         :updated_at,
                         :sort_title,
                         :holding_location

  delegate :members, :parent, :query_service, to: :wayfinder

  # TODO: Rename to decorated_collections
  def collections
    wayfinder.decorated_collections
  end

  # TODO: Rename to decorated_ephemera_box
  def ephemera_box
    wayfinder.decorated_ephemera_box
  end

  def ephemera_box_number
    ephemera_box.box_number if ephemera_box
  end

  def ephemera_project
    wayfinder.decorated_ephemera_projects.first
  end

  def rendered_date_range
    return unless first_range.present?
    first_range.range_string
  end

  def first_range
    @first_range ||= Array.wrap(date_range).map(&:decorate).first
  end

  def pdf_file
    pdf = file_metadata.find { |x| x.mime_type == ["application/pdf"] }
    pdf if pdf && Valkyrie::StorageAdapter.find(:derivatives).find_by(id: pdf.file_identifiers.first)
  rescue Valkyrie::StorageAdapter::FileNotFound
    nil
  end

  def rendered_holding_location
    value = holding_location
    return unless value.present?
    vocabulary = ControlledVocabulary.for(:holding_location)
    values = value.map do |holding_location|
      term = vocabulary.find(holding_location)
      next if term.nil?

      term.label
    end
    values.compact
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
          I18n.t("works.show.attributes.rights_statement.boilerplate").html_safe
        end
    end
  end

  def rendered_ocr_language
    return unless ocr_language.present?
    vocabulary = ControlledVocabulary.for(:ocr_language)
    ocr_language.map { |language| vocabulary.find(language).try(:label) }.compact
  end

  def collection_slugs
    @collection_slugs ||= Array.wrap(ephemera_project.try(:slug)) + collections.flat_map(&:slug)
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
    Array.wrap(super).first
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
      if value.is_a? EphemeraTerm
        value = value.decorate if value.is_a? EphemeraTerm
        linked_category = link_to_facet_search(field: "display_subject_ssim", value: value.vocabulary.label)
        # Don't link to both if they're the same
        if value.label == value.vocabulary.label
          linked_category
        else
          "#{linked_category} -- #{link_to_facet_search(field: 'display_subject_ssim', value: value.label)}".html_safe
        end
      else
        value
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

  # Should this folder have a manifest?
  # @return [TrueClass, FalseClass]
  def manifestable_state?
    if ephemera_box.nil? || !ephemera_box.manifestable_state?
      super
    else
      # box is in production; we should publish
      true
    end
  end

  # Is this folder publicly viewable?
  # @return [TrueClass, FalseClass]
  def public_readable_state?
    if ephemera_box.nil? || !ephemera_box.grant_access_state?
      super
    else
      # box is in production; it's public
      true
    end
  end

  # Should read groups be indexed for this folder?
  # @return [TrueClass, FalseClass]
  def index_read_groups?
    index_read_group_state? || (!ephemera_box.nil? && ephemera_box.grant_access_state?)
  end

  private

    def index_read_group_state?
      workflow_class.index_read_groups_states.include? Array.wrap(state).first.underscore
    end

    # Try to find pre-loaded resources from FindMembersWithRelationship first,
    # fall back to loading otherwise.
    def find_resource(resource_id)
      loaded_resources.find { |x| x.id == resource_id }&.decorate || query_service.find_by(id: resource_id).decorate
    rescue Valkyrie::Persistence::ObjectNotFoundError
      Rails.logger.warn "Failed to find the resource #{resource_id}"
      resource_id
    end

    def loaded_resources
      @loaded_resources ||= object.try(:loaded)&.values&.inject(&:+) || []
    end

    # Unsure if I should move this to wayfinder.
    def controlled_value_for(value)
      value.present? && value.is_a?(Valkyrie::ID) ? find_resource(value) : value
    end

    def link_to_facet_search(field:, value:)
      # I'm not sure why we can't use catalog_path. but root_path is essentially the same
      query = { "f[#{field}][]" => value }.to_param
      h.link_to value, "#{h.root_path}?#{query}"
    end
end
