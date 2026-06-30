class CollectionDecorator < Valkyrie::ResourceDecorator
  include DigitalCollectionsMetadata
  delegate :members, :parents, :collections, :members_count, to: :wayfinder
  display Schema::Common.attributes, :owners, :restricted_viewers
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

    # Rows to include in the digital collections metadata panel on the show
    # page. Logic in DigitalCollectionsMetadata class.
    def digital_collections_rows
      [
        rendered_dc_url,
        rendered_dpul_url,
        rendered_manifest_url,
        rendered_banner_image
      ]
    end
end
