# frozen_string_literal: true
class EphemeraTemplateDecorator < Valkyrie::ResourceDecorator
  self.displayed_attributes = []

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end
end
