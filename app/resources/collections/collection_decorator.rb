# frozen_string_literal: true
class CollectionDecorator < Valkyrie::ResourceDecorator
  delegate :members, :parents, :collections, :members_count, :media_resources, to: :wayfinder
  display :owners, :restricted_viewers

  def title
    Array(super).first
  end

  def manageable_files?
    false
  end

  def slug
    Array.wrap(super).first
  end

  # Access the resources attributes exposed for the IIIF Manifest metadata
  # @return [Hash] a Hash of all of the resource attributes
  def iiif_manifest_attributes
    super.merge iiif_manifest_exhibit
  end

  def human_readable_type
    if model.change_set
      I18n.translate("models.#{model.change_set}", default: model.class.to_s)
    else
      super
    end
  end

  private

    # Generate the Hash for the IIIF Manifest metadata exposing the slug as an "Exhibit" property
    # @return [Hash] the exhibit metadata hash
    def iiif_manifest_exhibit
      { exhibit: slug }
    end
end
