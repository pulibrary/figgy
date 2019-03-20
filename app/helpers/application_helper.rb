# frozen_string_literal: true
module ApplicationHelper
  include ::BlacklightHelper
  include ::Blacklight::LayoutHelperBehavior

  # Figgy resource types that can be created in the UI
  # @return [Array<Resource>]
  def all_works
    [ScannedResource, MediaResource, ScannedMap, RasterResource, VectorResource, NumismaticIssue, Playlist]
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
    return accession_link(attribute, value) if attribute == :accession_number && @document.decorated_resource.is_a?(CoinDecorator) && @document.decorated_resource.accession
    return catalog_link(attribute, value) if attribute == :source_metadata_identifier

    value
  end

  def catalog_link(_attribute, value)
    return value unless RemoteRecord.bibdata?(value)
    link_to value, "https://catalog.princeton.edu/catalog/#{value}"
  end

  def accession_link(_attribute, _value)
    link_to(@document.decorated_resource.accession_label, solr_document_path(id: @document.decorated_resource.accession_id))
  end

  # Classes added to a document's sidebar div. Overrides blacklight helper.
  # See: https://github.com/projectblacklight/blacklight/blob/master/app/helpers/blacklight/layout_helper_behavior.rb
  def show_sidebar_classes
    "col-xs-12"
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
    config_path = universal_viewer_config_path(resource)

    "/uv/uv#?manifest=#{manifest_url(resource)}&config=#{root_url}/uv/#{config_path}"
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
    query_params = search_state.reset(current_query_params).to_hash unless current_query_async?

    if search_session["counter"]
      per_page = (search_session["per_page"] || default_per_page).to_i
      counter = search_session["counter"].to_i

      query_params[:per_page] = per_page unless search_session["per_page"].to_i == default_per_page
      query_params[:page] = ((counter - 1) / per_page) + 1
    end

    link_url = if query_params.blank?
                 search_action_path(only_path: true)
               else
                 # This handles cases where the previous query has been cleared
                 query_params[:q] = "" unless query_params.key?("q")
                 scope.url_for(query_params)
               end
    label = opts.delete(:label)

    label ||= t("blacklight.back_to_bookmarks") if link_url =~ /bookmarks/

    label ||= t("blacklight.back_to_search")

    link_to label, link_url, opts
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

    # Generate the config. path for the Universal Viewer depending upon whether
    # the resource should have downloads enabled for the user
    # @param resource [Valkyrie::Resource] the resource being viewed
    # @return [Boolean]
    def universal_viewer_config_path(resource)
      if resource.decorate.downloadable? || (!current_user.nil? && (current_user.staff? || current_user.admin?))
        return "uv_config.json"
      end

      "uv_config_downloads_disabled.json"
    end
end
