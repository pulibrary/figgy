# frozen_string_literal: true
module ApplicationHelper
  include ::BlacklightHelper
  include ::Blacklight::LayoutHelperBehavior

  # Figgy resource types that can be created in the UI
  # @return [Array<Resource>]
  def all_works
    [ScannedResource, ScannedMap, RasterResource, VectorResource, Numismatics::Issue, Playlist]
  end

  # Localized application name
  # @return [String]
  def application_name
    t("product_name", default: super)
  end

  # Determines if user has permission to create at least one type of resource
  # @return [Boolean]
  def can_ever_create_works?
    !creatable_works.empty?
  end

  # Constructs a title using application name
  # @return [String]
  def construct_page_title(*elements)
    (elements.flatten.compact + [application_name]).join(" // ")
  end

  # Determines the bootstrap container type based on layout
  # @return [String] container-fluid, container
  def container_type
    if ordermanager_layout?
      "container-fluid"
    else
      "container"
    end
  end

  # Returns a polymorphic path for linking to file sets in File Manager
  # @param child [Resource] child resource
  # @param parent [ChangeSet] parent change set
  # @return [String]
  def contextual_path(child, parent)
    ContextualPath.new(child: child, parent_id: parent.try(:id))
  end

  # Figgy resource types that the user has permission to create
  # @return [Array<Resource>]
  def creatable_works
    all_works.select do |work|
      can?(:create, work)
    end
  end

  # Returns a decorated version of a change set's resource
  # @return [Valkyrie::ResourceDecorator]
  def decorated_change_set_resource
    @decorated_change_set_resource ||= @change_set.resource.decorate
  end

  # Returns a decorated version of the document presenter resource
  # @return [Valkyrie::ResourceDecorator]
  def decorated_resource
    @document.decorated_resource
  end

  # Generates a page title
  # @return [String]
  def default_page_title
    text = controller_name.singularize.titleize
    text = "#{action_name.titleize} " + text if action_name
    construct_page_title(text)
  end

  # URL for directly querying Figgy for a specific field and value
  # @param field [String] Solr field name
  # @param value [String] field value to query
  # @return [String]
  def facet_search_url(field:, value:)
    query = { "f[#{field}][]" => value }.to_param
    "#{root_path}?#{query}"
  end

  # Returns index page content class
  # @return [String]
  def main_content_classes
    if !has_search_parameters?
      "col-xs-12"
    else
      super
    end
  end

  # Gets current layout for use in rendering partials
  # @return [String] ordermanager, default
  def layout_type
    if params[:action] == "order_manager"
      "ordermanager"
    else
      "default"
    end
  end

  # Determines if odermanager is the current layout type
  # @return [Boolean]
  def ordermanager_layout?
    layout_type == "ordermanager"
  end

  # Returns the resource associated with the document presenter
  # @return [Resource]
  def resource
    @document.resource
  end

  def build_authorized_link
    viewer_url = "#{root_url}viewer#?manifest=#{polymorphic_url([:manifest, resource], auth_token: resource.auth_token)}"
    link_to viewer_url, viewer_url
  end

  # Renders an attribute value based on attribute name
  # @param attribute [Symbol] the attribute name
  # @param value [String] the value of the attribute
  # @return [String]
  def resource_attribute_value(attribute, value)
    linked_attributes = [:member_of_collections, :decorated_numismatic_monograms]
    return link_to(value.title, solr_document_path(id: value.id)) if linked_attributes.include?(attribute)
    return catalog_link(attribute, value) if attribute == :source_metadata_identifier

    value
  end

  def catalog_link(_attribute, value)
    url = RemoteRecord.record_url(value)
    return value unless url
    link_to value, url
  end

  # Classes added to a document's sidebar div. Overrides blacklight helper.
  # See: https://github.com/projectblacklight/blacklight/blob/master/app/helpers/blacklight/layout_helper_behavior.rb
  def show_sidebar_classes
    "show-sidebar col-lg-12"
  end

  def sidebar_classes
    if action_name == "show"
      show_sidebar_classes
    else
      super
    end
  end

  # Renders a span tag based on resource visibility value and workflow state
  # @param [String] visibility value
  # @param [Boolean] whether the workflow state is publicly readable
  # @return [String]
  def visibility_badge(value, public_readable_state = nil)
    PermissionBadge.new(value, public_readable_state).render
  end

  # Retrieve the authorization token from the request parameters
  # @return [String]
  def auth_token_param
    params[:auth_token]
  end

  # Generate the path for the IIIF manifest generated for resources
  # @param [Resource]
  # @return [String]
  def manifest_path(resource)
    path_args = [[:manifest, resource]]
    path_args << { auth_token: auth_token_param } if auth_token_param
    polymorphic_path(*path_args)
  end

  # Generate the url for the IIIF manifest generated for resources
  # @param [Resource]
  # @return [String]
  def manifest_url(resource)
    "#{request.base_url}#{manifest_path(resource)}"
  end

  # Generate the path for the Universal Viewer iframe @src attribute
  # @param [Valkyrie::Resource]
  # @return [String]
  def universal_viewer_path(resource)
    "/viewer#?manifest=#{manifest_url(resource)}"
  end

  # Convenience method for a fileset download path
  # @param [FileSet] the fileset to provide a download link to
  # @param [Hash] querystring options, for example an auth token to pass through
  def fileset_download_path(fileset, opts = {})
    download_path(fileset.id, fileset.file_metadata.first.id, opts)
  end

  def figgy_pdf_path(resource)
    polymorphic_path([:pdf, resource]) if pdf_allowed?(resource)
  end

  def pdf_allowed?(resource)
    return false unless pdf_types.include?(resource.class)
    ["color", "gray", "bitonal"].include?(resource&.pdf_type&.first)
  end

  def pdf_types
    [
      Numismatics::Coin,
      EphemeraFolder,
      ScannedMap,
      ScannedResource
    ]
  end

  def bulk_edit?
    collection_present? || bulk_editable_types_present?
  end

  def bulk_editable_types
    [
      "Coin",
      "Raster Resource",
      "Scanned Map",
      "Vector Resource"
    ]
  end

  def bulk_editable_types_present?
    return false unless params[:f] && params[:f]["human_readable_type_ssim"].present?
    bulk_editable_types.any? do |type|
      params[:f]["human_readable_type_ssim"] == [type]
    end
  end

  def collection_present?
    params[:f] && params[:f]["member_of_collection_titles_ssim"].present?
  end

  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  # @example
  #   link_back_to_catalog(label: 'Back to Search')
  #   link_back_to_catalog(label: 'Back to Search', route_set: my_engine)
  # @see Blacklight::UrlHelperBehavior#link_back_to_catalog
  def link_back_to_catalog(opts = { label: nil })
    scope = opts.delete(:route_set) || self
    # Filter for cases where the query params were cached by AJAX queries from
    # the client

    if current_query_async?
      query_params = {}
    else
      query_params = search_state.reset(current_query_params).to_hash

      if search_session["counter"]
        per_page = (search_session["per_page"] || default_per_page).to_i
        counter = search_session["counter"].to_i

        query_params[:per_page] = per_page unless search_session["per_page"].to_i == default_per_page
        query_params[:page] = ((counter - 1) / per_page) + 1
      end
    end

    # query_params = search_state.reset(current_query_params).to_hash unless current_query_async?

    link_url = if query_params.blank?
                 search_action_path(only_path: true)
               else
                 # This handles cases where the previous query has been cleared
                 query_params[:q] = "" unless query_params.key?("q")
                 scope.url_for(query_params)
               end

    label = opts.delete(:label)
    label ||= t("blacklight.back_to_bookmarks") if /bookmarks/.match?(link_url)
    label ||= t("blacklight.back_to_search")

    link_to label, link_url, opts
  end

  # Determine whether or not "Save and Duplicate Metadata" should be offered for a given Resource
  # @param resource [Resource]
  # @return [Boolean]
  def support_save_and_duplicate?(resource:)
    resource.class.supports_save_and_duplicate? && params[:controller] == resource.class.name.underscore.pluralize
  end

  private

    # Retrieve the current search query parameters from the HTTP request
    # @return [Hash]
    def current_query_params
      values = current_search_session.try(:query_params)
      values.to_h
    end

    # Determine whether or not the current query is asynchronous (i. e. AJAX)
    # @return [Boolean]
    def current_query_async?
      current_query_params.fetch("async", nil) == "true"
    end
end
