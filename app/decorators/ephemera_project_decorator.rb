# frozen_string_literal: true
class EphemeraProjectDecorator < Valkyrie::ResourceDecorator
  display(:title)

  def members
    @members ||= query_service.find_members(resource: model).to_a
  end

  def boxes
    @boxes ||= query_service.find_members(resource: model, model: EphemeraBox).map(&:decorate).to_a
  end

  def fields
    @fields ||= query_service.find_members(resource: model, model: EphemeraField).map(&:decorate).to_a
  end

  def folders
    @folders ||= query_service.find_members(resource: model, model: EphemeraFolder).map(&:decorate).to_a
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

  def top_language
    super.map { |id| query_service.find_by(id: id) }
  end

  # Access the resources attributes exposed for the IIIF Manifest metadata
  # @return [Hash] a Hash of all of the resource attributes
  def iiif_manifest_attributes
    super.merge iiif_manifest_exhibit
  end

  private

    # Generate the Hash for the IIIF Manifest metadata exposing the slug as an "Exhibit" property
    # @return [Hash] the exhibit metadata hash
    def iiif_manifest_exhibit
      { exhibit: slug }
    end
end
