module DigitalCollectionsMetadata
  # Render digital collections metadata as a striped table.
  def digital_collections_attributes
    rows = digital_collections_rows.compact.join("\n")

    <<~HTML.html_safe
      <table class="table digital-collections-metadata">
        <tbody>
          #{rows}
        </tbody>
      </table>
    HTML
  end

  private

    def rendered_dc_url
      return unless publish
      digital_collections_row("Digital Collections URL", "rendered_dc_url",
        rendered_link("https://digital-collections.princeton.edu/collections/#{slug}"))
    end

    def rendered_dpul_url
      digital_collections_row("DPUL URL", "rendered_dpul_url",
        rendered_link("https://dpul.princeton.edu/#{slug}"))
    end

    def rendered_manifest_url
      digital_collections_row("IIIF Manifest URL", "rendered_manifest_url",
        rendered_link(helpers.manifest_collection_url(self)))
    end

    def rendered_banner_image
      return if banner_image_url.blank?
      digital_collections_row("Banner Image", "rendered_banner_image",
        "<img style=\"width: 50%;\" src=\"#{banner_image_url}\" />")
    end

    def digital_collections_row(label, css_class, value)
      <<~HTML
        <tr>
          <th>#{label}</th>
          <td class="#{css_class}">#{value}</td>
        </tr>
      HTML
    end

    def rendered_link(url)
      "<a href=\"#{url}\">#{url}</a>"
    end
end
