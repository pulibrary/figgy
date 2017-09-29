# frozen_string_literal: true
class Valkyrie::ResourceDecorator < ApplicationDecorator
  self.suppressed_attributes = [
    :depositor,
    :description,
    :holding_location,
    :keyword,
    :nav_date,
    :ocr_language,
    :pdf_type,
    :rights_statement,
    :sort_title,
    :source_jsonld,
    :source_metadata,
    :source_metadata_identifier,
    :title
  ]
  self.suppressed_attributes += imported_attributes(suppressed_attributes)
  self.display_attributes = [:internal_resource, :created_at, :updated_at]

  def created_at
    output = super
    return if output.blank?
    output.strftime("%D %r %Z")
  end

  def updated_at
    output = super
    return if output.blank?
    output.strftime("%D %r %Z")
  end

  def visibility
    Array(super).map do |visibility|
      h.visibility_badge(visibility)
    end
  end

  def header
    Array(title).to_sentence
  end

  def manageable_files?
    true
  end

  def manageable_structure?
    false
  end

  def attachable_objects
    []
  end

  def heading
    Array.wrap(title).first
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
  delegate :query_service, to: :metadata_adapter
end
