# frozen_string_literal: true
module ApplicationHelper
  include ::BlacklightHelper
  include ::Blacklight::LayoutHelperBehavior

  def application_name
    t("product_name", default: super)
  end

  def default_page_title
    text = controller_name.singularize.titleize
    text = "#{action_name.titleize} " + text if action_name
    construct_page_title(text)
  end

  def construct_page_title(*elements)
    (elements.flatten.compact + [application_name]).join(" // ")
  end

  def contextual_path(child, parent)
    ContextualPath.new(child: child, parent_id: parent.try(:id))
  end

  def main_content_classes
    if !has_search_parameters?
      "col-xs-12"
    else
      super
    end
  end

  def show_sidebar_classes
    "col-xs-12"
  end

  def can_ever_create_works?
    !creatable_works.empty?
  end

  def creatable_works
    all_works.select do |work|
      can?(:create, work)
    end
  end

  def all_works
    [ScannedResource, MediaResource, ScannedMap, RasterResource, VectorResource]
  end

  def resource
    @document.resource
  end

  def decorated_resource
    @document.decorated_resource
  end

  def decorated_change_set_resource
    @decorated_change_set_resource ||= @change_set.resource.decorate
  end

  def ordermanager_layout?
    layout_type == "ordermanager"
  end

  def container_type
    if ordermanager_layout?
      "container-fluid"
    else
      "container"
    end
  end

  ##
  # Gets current layout for use in rendering partials
  # @return [String] ordermanager, default
  def layout_type
    if params[:action] == "order_manager"
      "ordermanager"
    else
      "default"
    end
  end

  def visibility_badge(value)
    PermissionBadge.new(value).render
  end

  def facet_search_url(field:, value:)
    query = { "f[#{field}][]" => value }.to_param
    "#{root_path}?#{query}"
  end

  # Renders an attribute value based on attribute name.
  # For display in attribute values table on resource show page.
  # @param attribute [Symbol] the attribute name
  # @param value [String] the value of the attribute
  # @return [String]
  def resource_attribute_value(attribute, value)
    if attribute == :member_of_collections
      link_to value.title, solr_document_path(id: value.id)
    else
      value
    end
  end
end
