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
                     .to_a
                     .map(&:decorate)
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
  # @return [Array<MetadataObject>] an array of objects modeling the metadata values
  def iiif_metadata
    iiif_manifest_attributes.select { |_, value| value.present? }.map do |u, v|
      MetadataObject.new(u, v).to_h
    end
  end

  # Models metadata values within a manifest
  class MetadataObject
    # Constructor
    # @param [Symbol] (symbolized) metadata attribute name
    # @param [Object] metadata attribute value
    def initialize(attribute, value)
      @attribute = attribute
      @value = value
    end

    # Provides the label for a given metadata attribute
    # @return [String] the label
    def label
      if respond_to?("#{@attribute}_label".to_sym)
        send("#{@attribute}_label".to_sym)
      else
        @attribute.to_s.titleize
      end
    end

    # Overrides the label for the attribute :pdf_type
    # @return [String] the label
    def pdf_type_label
      'PDF Type'
    end

    # Parses and formats date-string values
    # @return [Array<String>] the formatted date strings
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

    # Aliases all methods which may contain date strings
    alias created_value date_value
    alias imported_created_value created_value
    alias updated_value date_value
    alias imported_updated_value updated_value
    private :date_value

    # For identifiers containing URL's into markup, generates HTML link markup
    # @return [Array<String>] HTML markup for links, or the original identifiers
    def identifier_value
      @value.map do |id|
        if id =~ /^https?\:\/\//
          "<a href='#{id}' alt='#{label}'>#{id}</a>"
        else
          id
        end
      end
    end

    # Aliases the method for imported identifiers
    alias imported_identifier_value identifier_value

    # Generates a resource transformed into linked data (only if it is an EphemeraTerm)
    # Otherwise, the original Object is returned
    # @return [Array<LinkedResource, Object>] the linked or unlinked resources
    def linkable_value
      values = Array.wrap(@value)
      values.map do |element|
        return element unless element.is_a?(EphemeraTerm)

        factory = LinkedData::LinkedResourceFactory.new(resource: element)
        factory.new.without_context
      end
    end

    # Aliases all methods which may contain linked data terms
    alias geo_subject_value linkable_value
    alias genre_value_value linkable_value
    alias geographic_origin_value linkable_value
    alias language_value linkable_value
    alias subject_value linkable_value
    private :linkable_value

    # Attempts to use an overridden method for transforming metadata values
    # @return [Array<Object>] the array of metadata values
    def value
      Array.wrap(
        if respond_to?("#{@attribute}_value".to_sym)
          send("#{@attribute}_value".to_sym)
        else
          @value
        end
      )
    end

    # Provides a Hash representation of the metadata attribute name/value mapping
    # @return [Hash]
    def to_h
      { 'label' => label, 'value' => value }
    end

    private

      # Determine if the first and last elements within an array of date strings each only capture a range of years
      # @param [Array<String>] the array of date-strings
      # @return [TrueClass, FalseClass]
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
