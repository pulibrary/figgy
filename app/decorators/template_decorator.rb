# frozen_string_literal: true
class TemplateDecorator < Valhalla::ResourceDecorator
  def template_label
    title.first
  end
end
