# frozen_string_literal: true
class Embed
  def self.for(resource:, ability:)
    new(resource: resource, ability: ability)
  end

  attr_reader :resource, :ability
  def initialize(resource:, ability:)
    @resource = resource
    @ability = ability
  end

  def to_graphql
    {
      html: build_html,
      status: build_status
    }
  end

  private

    def build_html
      return unless embed_authorized?
      if viewer_enabled?
        build_iframe
      else
        build_link
      end
    end

    def helper
      @helper ||= ManifestBuilder::ManifestHelper.new
    end

    def build_link
      "<a href='#{helper.download_url(file_set, file_set.primary_file)}'>Download Content</a>"
    end

    def build_iframe
      viewer_url = helper.viewer_index_url
      manifest_url = ManifestBuilder::ManifestHelper.new.manifest_url(resource)
      %(<iframe allowfullscreen="true" id="uv_iframe" src="#{viewer_url}#?manifest=#{manifest_url}"></iframe>)
    end

    # I'm allowed to embed if:
    #   I can download the first file set (use case: a zip file)
    #   I can read the resource (use case: a viewer)
    def embed_authorized?
      ability.can?(:download, file_set) || ability.can?(:manifest, resource)
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

    def viewer_enabled?
      !(file_set&.mime_type || []).include?("application/zip")
    end

    def file_set
      @file_set ||= Wayfinder.for(resource).file_sets.first
    end
end
