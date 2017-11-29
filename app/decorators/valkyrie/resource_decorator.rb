# frozen_string_literal: true
class Valkyrie::ResourceDecorator < ApplicationDecorator
  display(
    [
      :internal_resource,
      :created_at,
      :updated_at
    ]
  )
  suppress(
    [
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
  )

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
    merged_titles
  end

  def first_title
    Array.wrap(title).first
  end

  def merged_titles
    Array.wrap(title).join('; ')
  end

  def titles
    Array.wrap(title)
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

  # prepare metadata as an array of label/value hash pairs
  # as required by samvera-labs/iiif_manifest
  def iiif_metadata
    iiif_manifest_attributes.select { |_, value| value.present? }.map do |u, v|
      MetadataObject.new(u, v).to_h
    end
  end

  class MetadataObject
    def initialize(attribute, value)
      @attribute = attribute
      @value = value
    end

    def pdf_type_label
      'PDF Type'
    end

    def label
      if respond_to?("#{@attribute}_label".to_sym)
        send("#{@attribute}_label".to_sym)
      else
        @attribute.to_s.titleize
      end
    end

    def date_value
      @value.map do |date|
        date.split("/").map do |d|
          if year_only(date.split("/"))
            Date.parse(d).strftime("%Y")
          else
            Date.parse(d).strftime("%m/%d/%Y")
          end
        end.join("-")
      end
    rescue => e
      Rails.logger.warn e.message
      @value
    end

    alias created_value date_value
    alias imported_created_value created_value
    alias updated_value date_value
    alias imported_updated_value updated_value
    private :date_value

    def identifier_value
      @value.map do |id|
        if id =~ /^https?\:\/\//
          "<a href='#{id}' alt='#{label}'>#{id}</a>"
        else
          id
        end
      end
    end

    alias imported_identifier_value identifier_value

    def value
      Array.wrap(
        if respond_to?("#{@attribute}_value".to_sym)
          send("#{@attribute}_value".to_sym)
        else
          @value
        end
      )
    end

    def to_h
      { 'label' => label, 'value' => value }
    end

    private

      def year_only(dates)
        dates.length == 2 && dates.first.end_with?("-01-01T00:00:00Z") && dates.last.end_with?("-12-31T23:59:59Z")
      end
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
