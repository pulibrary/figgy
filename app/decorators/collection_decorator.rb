# frozen_string_literal: true
class CollectionDecorator < Valkyrie::ResourceDecorator
  def title
    Array(super).first
  end

  def manageable_files?
    false
  end

  def members
    @members ||= query_service.find_inverse_references_by(resource: model, property: :member_of_collection_ids).to_a
  end

  # Nested collections are not currently supported
  def parents
    []
  end

  alias collections parents

  def slug
    Array.wrap(super).first
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
