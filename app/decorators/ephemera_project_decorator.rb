# frozen_string_literal: true
class EphemeraProjectDecorator < Valkyrie::ResourceDecorator
  display :title
  delegate :members, :query_service, :decorated_folders_with_genres, to: :wayfinder

  # TODO: Rename to decorated_ephemera_boxes
  def boxes
    wayfinder.decorated_ephemera_boxes
  end

  # TODO: Rename to decorated_ephemera_fields
  def fields
    wayfinder.decorated_ephemera_fields
  end

  # TODO: Rename to decorated_ephemera_folders
  def folders
    wayfinder.decorated_ephemera_folders
  end

  # TODO: Rename to ephemera_folders_count
  def folders_count
    wayfinder.ephemera_folders_count
  end

  # TODO: Rename to decorated_templates
  def templates
    wayfinder.decorated_templates
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
