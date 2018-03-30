# frozen_string_literal: true
module ApplicationHelper
  include ::BlacklightHelper
  include ::Blacklight::LayoutHelperBehavior
  include Valhalla::ApplicationHelper
  include Valhalla::ContextualPathHelper

  def application_name
    t('valhalla.product_name', default: super)
  end

  def default_page_title
    text = controller_name.singularize.titleize
    text = "#{action_name.titleize} " + text if action_name
    construct_page_title(text)
  end

  def construct_page_title(*elements)
    (elements.flatten.compact + [application_name]).join(' // ')
  end

  def main_content_classes
    if !has_search_parameters?
      'col-xs-12'
    else
      super
    end
  end

  def show_sidebar_classes
    'col-xs-12'
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

  def filemanager_layout?
    layout_type == 'filemanager'
  end

  def container_type
    if filemanager_layout?
      'container-fluid'
    else
      'container'
    end
  end

  ##
  # Gets current layout for use in rendering partials
  # @return [String] filemanager, default
  def layout_type
    resource_types = ['scanned_resources', 'ephemera_folders']
    if resource_types.include? params[:controller]
      'filemanager'
    else
      'default'
    end
  end
end
