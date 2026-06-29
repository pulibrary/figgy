class EphemeraProjectDecorator < Valkyrie::ResourceDecorator
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

  def digital_collections_attributes
    rows = [
      rendered_dc_url,
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
