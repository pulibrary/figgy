# frozen_string_literal: true
class EphemeraProjectDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:title]
  delegate :query_service, to: :metadata_adapter

  def members
    @members ||= query_service.find_members(resource: model)
  end

  def boxes
    @boxes ||= members.select { |r| r.is_a?(EphemeraBox) }.map(&:decorate).to_a
  end

  def fields
    @fields ||= members.select { |r| r.is_a?(EphemeraField) }.map(&:decorate).to_a
  end

  def templates
    @templates ||= query_service.find_inverse_references_by(resource: self, property: :parent_id).map(&:decorate).to_a
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

  def title
    super.first
  end
end
