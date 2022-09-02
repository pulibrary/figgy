# frozen_string_literal: true
class Valkyrie::ResourceDecorator < ApplicationDecorator
  display :internal_resource, :created_at, :updated_at
  suppress :depositor,
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
  delegate :members, :parents, to: :wayfinder

  def wayfinder
    @wayfinder ||= Wayfinder.for(object)
  end

  # resource decorators will use this method if they define :member_of_collections
  #   in self.display_attributes
  def member_of_collections
    return [] unless model.respond_to?(:member_of_collection_ids)
    wayfinder.decorated_collections
  end

  def ark
    Ark.new(identifier).uri
  end

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
      h.visibility_badge(visibility, public_readable_state?, embargoed?)
    end
  end

  def visibility_badge
    Array(attributes[:visibility]).map do |visibility|
      h.visibility_badge(visibility)
    end
  end

  # Calculate a histogram of child FileSet fixity status
  def fixity_map
    return [] unless respond_to?(:file_sets)
    @fixity_map ||=
      begin
        m = {}
        m[0] = wayfinder.deep_failed_local_fixity_count if wayfinder.deep_failed_local_fixity_count.positive?
        m[1] = wayfinder.deep_succeeded_local_fixity_count if wayfinder.deep_succeeded_local_fixity_count.positive?
        m
      end
  end

  def cloud_fixity_map
    return [] unless respond_to?(:file_sets)
    unknown_count = wayfinder.deep_file_set_count - wayfinder.deep_failed_cloud_fixity_count - wayfinder.deep_succeeded_cloud_fixity_count
    @cloud_fixity_map ||=
      begin
        m = {}
        m[0] = wayfinder.deep_failed_cloud_fixity_count if wayfinder.deep_failed_cloud_fixity_count.positive?
        m[1] = wayfinder.deep_succeeded_cloud_fixity_count if wayfinder.deep_succeeded_cloud_fixity_count.positive?
        m[nil] = unknown_count if unknown_count.positive?
        m
      end
  end

  def fixity_badges
    fixity_map.map do |status, count|
      h.format_fixity_count(status, count)
    end.join(" ")
  end

  def fixity_summary
    fixity_map.map do |status, count|
      h.format_fixity_status(status, count)
    end.join(" ")
  end

  def cloud_fixity_summary
    cloud_fixity_map.map do |status, count|
      h.format_fixity_status(status, count)
    end.join(" ")
  end

  def header
    merged_titles
  end

  def first_title
    Array.wrap(title).first
  end

  def merged_titles
    Array.wrap(title).join("; ")
  end

  def titles
    Array.wrap(title)
  end

  def manageable_files?
    true
  end

  def orderable_files?
    manageable_files?
  end

  def manageable_order?
    true
  end

  def manageable_structure?
    false
  end

  # Determine whether or not a resource is publicly visible
  # @return [Boolean]
  def visible?
    model.respond_to?(:visibility) && model.visibility.include?(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end

  # Determine whether or not a resource can be downloaded
  # @return [Boolean]
  def downloadable?
    return false unless respond_to?(:downloadable)
    return visible? && public_readable_state? if downloadable.nil?
    return false unless visible?

    downloadable&.include?("public")
  end

  def attachable_objects
    []
  end

  delegate :metadata_adapter, :query_service, to: :wayfinder

  # prepare metadata as an array of label/value hash pairs
  # as required by samvera-labs/iiif_manifest
  # @return [Array<MetadataObject>] an array of objects modeling the metadata values
  def iiif_metadata
    iiif_manifest_attributes.select { |k, v| !iiif_suppressed_metadata.include?(k) && v.present? }.map do |u, v|
      MetadataObject.new(u, v).to_h
    end
  end

  def iiif_suppressed_metadata
    @suppressed_metadata ||= [
      :created,
      :created_at,
      :depositor,
      :description, # this is included in the manifest builder
      :pdf_type,
      :references,
      :updated_at
    ]
  end

  # Should this resource have a manifest?
  # @return [TrueClass, FalseClass]
  def manifestable_state?
    return true unless manages_state?
    workflow_class.manifest_states.include? Array.wrap(state).first.underscore
  end

  # Does the state allow this resource to be publicly viewable (regardless of actual visibility setting)
  # @return [TrueClass, FalseClass]
  def public_readable_state?
    return true unless manages_state?
    workflow_class.public_read_states.include? Array.wrap(state).first.underscore
  end

  # Is the resource embargoed?
  # @return [TrueClass, FalseClass]
  def embargoed?
    if embargo_date_time.present?
      embargo_date_time > Time.now.in_time_zone("Eastern Time (US & Canada)")
    else
      # For MVWs, inherit embargo state from parent.
      return unless persisted?
      wayfinder.parent&.decorate.try(:embargoed?) || false
    end
  end

  def embargo_date_time
    @embargo_date_time ||=
      begin
        return if model.try(:embargo_date).blank?
        m, d, y = model.embargo_date.split("/")
        return false unless m && d && y
        Time.use_zone("Eastern Time (US & Canada)") do
          Time.zone.parse("#{y}-#{m}-#{d}").midnight
        end
      end
  end

  # Should this simple resource have an ARK minted?
  # @return [TrueClass, FalseClass]
  def ark_mintable_state?
    return false unless manages_state?
    workflow_class.ark_mint_states.include? Array.wrap(state).first&.underscore
  end

  # If no read_groups then only Figgy admins can see this item.
  def private_visibility?
    try(:read_groups).blank?
  end

  def workflow_class
    @workflow_class ||=
      begin
        change_set = ChangeSet.for(model)
        change_set.try(:workflow_class) || raise(WorkflowRegistry::EntryNotFound)
      rescue ChangeSet::NotFoundError
        raise(WorkflowRegistry::EntryNotFound)
      end
  end

  def manages_state?
    !workflow_class.nil? && respond_to?(:state) && !Array.wrap(state).first.nil?
  rescue WorkflowRegistry::EntryNotFound
    false
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

    # Overrides the label for the attribute :pdf_type
    # @return [String] the label
    def pdf_type_label
      "PDF Type"
    end

    # Parses and formats date-string values
    #   It it can't parse the string, returns it
    #   Date fields may hold programmatically- or human-created date strings.
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
        if /^https?\:\/\//.match?(id)
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
        element.linked_resource.without_context.fetch("pref_label")
      end
    end

    # Aliases all methods which may contain linked data terms
    alias geo_subject_value linkable_value
    alias genre_value linkable_value
    alias geographic_origin_value linkable_value
    alias language_value linkable_value
    alias subject_value linkable_value
    private :linkable_value

    # Ensures that only the titles of collections are specified within the Manifest metadata
    # @return [Array<String>] the collection titles
    def member_of_collections_value
      @value.map(&:title)
    end

    # Provides a Hash representation of the metadata attribute name/value mapping
    # @return [Hash]
    def to_h
      { "label" => label, "value" => value }
    end

    private

      # Determine if the first and last elements within an array of date strings each only capture a range of years
      # @param [Array<String>] the array of date-strings
      # @return [TrueClass, FalseClass]
      def year_only(dates)
        dates.length == 2 && dates.first.end_with?("-01-01T00:00:00Z") && dates.last.end_with?("-12-31T23:59:59Z")
      end
  end

  def form_input_values
    title_value = Array.wrap(title).first
    title = title_value.is_a?(RDF::Literal) ? title_value.value : title_value
    OpenStruct.new id: id.to_s, title: title
  end
end
