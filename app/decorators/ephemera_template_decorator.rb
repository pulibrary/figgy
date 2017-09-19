# frozen_string_literal: true
class EphemeraTemplateDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = []

  delegate :query_service, to: :metadata_adapter

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end
end
