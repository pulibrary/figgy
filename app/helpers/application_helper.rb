# frozen_string_literal: true
module ApplicationHelper
  include ::BlacklightHelper
  include ::Blacklight::LayoutHelperBehavior
  include Valhalla::ApplicationHelper

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
    if params[:action] == "index" && !has_search_parameters?
      'col-md-12'
    else
      super
    end
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
    [ScannedResource]
  end
end
