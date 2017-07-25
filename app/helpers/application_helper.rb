# frozen_string_literal: true
module ApplicationHelper
  include ::BlacklightHelper
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
end
