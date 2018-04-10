# frozen_string_literal: true
class StructureDecorator < Valhalla::ResourceDecorator
  def form_label
    label.first
  end
end
