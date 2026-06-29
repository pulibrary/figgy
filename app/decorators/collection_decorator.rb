class CollectionDecorator < Valkyrie::ResourceDecorator
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

  def digital_collections_attributes
    rows = [
      rendered_dc_url,
      rendered_dpul_url,
      rendered_manifest_url,
      rendered_banner_image
    ].compact.join("\n")

    <<~HTML.html_safe
      <table class="table digital-collections-metadata">
        <tbody>
          #{rows}
        </tbody>
      </table>
    HTML
  end

  private

    # Generate the Hash for the IIIF Manifest metadata exposing the slug as an "Exhibit" property
    # @return [Hash] the exhibit metadata hash
    def iiif_manifest_exhibit
      { exhibit: slug }
    end

    def rendered_dc_url
      return unless publish
      <<~HTML
        <tr>
          <th>Digital Collections URL</th>
          <td class="rendered_dc_url">#{rendered_link("https://digital-collections.princeton.edu/collections/#{slug}")}</td>
        </tr>
      HTML
    end

    def rendered_dpul_url
      <<~HTML
        <tr>
          <th>DPUL URL</th>
          <td class="rendered_dpul_url">#{rendered_link("https://dpul.princeton.edu/#{slug}")}</td>
        </tr>
      HTML
    end

    def rendered_manifest_url
      <<~HTML
        <tr>
          <th>IIIF Manifest URL</th>
          <td class="rendered_manifest_url">#{rendered_link(helpers.manifest_collection_url(self))}</td>
        </tr>
      HTML
    end

    def rendered_banner_image
      return if banner_image_url.blank?
      <<~HTML
        <tr>
          <th>Banner Image</th>
          <td class="rendered_banner_image"><img style="width: 50%;" src="#{banner_image_url}" /></td>
        </tr>
      HTML
    end

    def rendered_link(url)
      "<a href=\"#{url}\">#{url}</a>".html_safe
    end
end
