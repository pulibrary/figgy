# frozen_string_literal: true
class Valkyrie::ResourceDecorator < ApplicationDecorator
  self.suppressed_attributes = [
    :depositor,
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

  # resource decorators will use this method if they define :member_of_collections
  #   in self.display_attributes
  def member_of_collections
    return [] unless model.respond_to?(:member_of_collection_ids)
    @member_of_collections ||=
      begin
        query_service.find_references_by(resource: model, property: :member_of_collection_ids)
                     .map(&:decorate)
                     .map(&:title).to_a
      end
  end

  # Accesses all Resources referenced by a given Resource using the :member_ids property
  # @return [Array<Valkyrie::Resource>] an array of Resources (possibly empty)
  def members
    @members ||= find_members(resource: model)
  end

  # Accesses all Resources referencing a given Resource using the :member_ids property
  # i. e. it "accesses all Resources for which a given Resource is a member of"
  # @return [Array<Valkyrie::Resource>] an array of Resources (possibly empty)
  def parents
    @parents ||= find_parents(resource: model)
  end

  private

    # Queries the metadata adapter for all referenced resources for a given resource using :member_ids
    # Returns an empty Array rather than nil
    # @see Valkyrie::Persistence::Solr::Queries::FindMembersQuery
    # @return [Array<Valkyrie::Resource>] an array of Resources (possibly empty)
    def find_members(resource:)
      query_service.find_members(resource: resource) || []
    end

    # Queries the metadata adapter for all resources referencing a given resource using :member_ids
    # Returns an empty Array rather than nil
    # @see Valkyrie::Persistence::Solr::Queries::FindInverseReferencesQuery
    # @return [Array<Valkyrie::Resource>] an array of Resources (possibly empty)
    def find_parents(resource:)
      query_service.find_parents(resource: resource) || []
    end
end
