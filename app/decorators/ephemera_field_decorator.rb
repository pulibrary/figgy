# frozen_string_literal: true
class EphemeraFieldDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:name]
  delegate :query_service, to: :metadata_adapter

  def parents
    @parents ||= query_service.find_parents(resource: model)
  end

  def projects
    @projects ||= parents.select { |r| r.is_a?(EphemeraProject) }.map(&:decorate).to_a
  end

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
