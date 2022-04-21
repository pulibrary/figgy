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
    if ability.can?(:download, object)
      {
        html: build_iframe,
        status: "authorized"
      }
    else
      {
        html: nil,
        status: "unauthenticated"
      }
    end
  end

  private

    def build_iframe
      helper = ManifestBuilder::ManifestHelper.new
      viewer_url = helper.viewer_index_url
      manifest_url = ManifestBuilder::ManifestHelper.new.manifest_url(object)
      %(<iframe allowfullscreen="true" id="uv_iframe" src="#{viewer_url}#?manifest=#{manifest_url}"></iframe>)
    end
end
