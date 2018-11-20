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

  # Renders an attribute value based on attribute name
  # @param attribute [Symbol] the attribute name
  # @param value [String] the value of the attribute
  # @return [String]
  def resource_attribute_value(attribute, value)
    if attribute == :member_of_collections
      link_to value.title, solr_document_path(id: value.id)
    elsif attribute == :authorized_link
      # Build the authorized link attribute
      link_to(request.base_url + solr_document_path(id: resource.id, auth_token: value), solr_document_path(id: resource.id, auth_token: value))
    elsif attribute == :accession_number && @document.decorated_resource.is_a?(CoinDecorator) && @document.decorated_resource.accession
      link_to(@document.decorated_resource.accession_label, solr_document_path(id: @document.decorated_resource.accession_id))
    else
      value
    end
  end

  # Classes added to a document's sidebar div. Overrides blacklight helper.
  # See: https://github.com/projectblacklight/blacklight/blob/master/app/helpers/blacklight/layout_helper_behavior.rb
  def show_sidebar_classes
    "col-xs-12"
  end

  # Renders a span tag based on resource visibility value
  # @param [String] visibility value
  # @return [String]
  def visibility_badge(value)
    PermissionBadge.new(value).render
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

  # Generate the path for the Universal Viewer iframe @src attribute
  # @return [String]
  def universal_viewer_path(resource)
    "/uv/uv#?manifest=#{request.base_url}#{manifest_path(resource)}"
  end
end
