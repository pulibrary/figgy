# frozen_string_literal: true
class EphemeraProjectDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:title]

  def members
    @members ||= query_service.find_members(resource: model).to_a
  end

  def boxes
    @boxes ||= members.select { |r| r.is_a?(EphemeraBox) }.map(&:decorate).to_a
  end

  def fields
    @fields ||= members.select { |r| r.is_a?(EphemeraField) }.map(&:decorate).to_a
  end

  def folders
    @folders ||= members.select { |r| r.is_a?(EphemeraFolder) }.map(&:decorate).to_a
  end

  def templates
    @templates ||= query_service.find_inverse_references_by(resource: self, property: :parent_id).map(&:decorate).to_a
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

  def slug
    Array.wrap(super).first
  end

  def iiif_manifest_attributes
    local_attributes(self.class.iiif_manifest_attributes).merge iiif_manifest_exhibit
  end

  private

    # Generate the Hash for the IIIF Manifest metadata exposing the slug as an "Exhibit" property
    # @return [Hash] the exhibit metadata hash
    def iiif_manifest_exhibit
      { exhibit: slug }
    end
end
