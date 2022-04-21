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
    # If I can read and get a viewer for it, build iframe
    # If I can download and get a link, render link
    # If my first file set is a zip file, render link
    # Otherwise, build iframe
    if zip_file? && ability.can?(:download, file_set)
      {
        html: build_link,
        status: "authorized"
      }
    elsif ability.can?(:read, object)
      {
        html: build_iframe,
        status: "authorized"
      }
    elsif ability.current_user.anonymous?
      {
        html: nil,
        status: "unauthenticated"
      }
    else
      {
        html: nil,
        status: "unauthorized"
      }
    end
  end

  def zip_file?
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
