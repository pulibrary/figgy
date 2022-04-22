# frozen_string_literal: true
class Types::ScannedResourceType < Types::BaseObject
  implements Types::Resource

  field :start_page, String, null: true
  field :viewing_direction, Types::ViewingDirectionEnum, null: true
  field :manifest_url, String, null: true
  field :source_metadata_identifier, String, null: true

  def viewing_hint
    Array.wrap(super).first
  end

  def viewing_direction
    Array.wrap(super).first
  end

  def label
    Array.wrap(object.title).first
  end

  def start_page
    Array.wrap(object.start_canvas).first.to_s
  end

  def source_metadata_identifier
    Array.wrap(object.source_metadata_identifier).first
  end

  def embed
    # Embed.for(object, ability).to_graphql
    {
      html: build_html,
      status: build_status
    }
  end

  def build_html
    return unless embed_authorized?
    if zip_file?
      build_link
    else
      build_iframe
    end
  end

  # I'm allowed to embed if:
  #   I can download the first file set (use case: a zip file)
  #   I can read the resource (use case: a viewer)
  def embed_authorized?
    ability.can?(:download, file_set) || ability.can?(:manifest, object)
  end

  def build_status
    if embed_authorized?
      "authorized"
    elsif ability.current_user.anonymous?
      "unauthenticated"
    else
      "unauthorized"
    end
  end

  def zip_file?
    # !resource.viewer_enabled?
    (file_set&.mime_type || []).include?("application/zip")
  end

  def file_set
    @file_set ||= Wayfinder.for(object).file_sets.first
  end

  private

    def build_link
      "<a href='#{helper.download_url(file_set, file_set.primary_file)}'>Download Content</a>"
    end

    def build_iframe
      viewer_url = helper.viewer_index_url
      manifest_url = ManifestBuilder::ManifestHelper.new.manifest_url(object)
      %(<iframe allowfullscreen="true" id="uv_iframe" src="#{viewer_url}#?manifest=#{manifest_url}"></iframe>)
    end
end
