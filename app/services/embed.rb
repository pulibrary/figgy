# frozen_string_literal: true

# Use this class to provide the correct embed hashes for a given resource with
# the appropriate permissions enforced.
class Embed
  def self.for(resource:, ability:)
    new(resource: resource, ability: ability)
  end

  attr_reader :resource, :ability
  def initialize(resource:, ability: nil)
    @resource = resource
    @ability = ability
  end

  # Status conflates both authorization and authentication, preferencing
  # authorization first.
  # There will only be html content if the status is authorized.
  def to_graphql
    if embed_authorized?
      {
        type: build_type,
        content: build_content,
        media_type: build_media_type,
        status: "authorized"
      }
    else
      {
        type: nil,
        content: nil,
        media_type: nil,
        status: unauthorized_status
      }
    end
  end

  def to_dao
    if viewer_enabled?
      {
        "file_uri" => helper.manifest_url(resource),
        "use_statement" => "https://iiif.io/api/presentation/2.1/"
      }
    else
      {
        "file_uri" => helper.download_url(file_set, file_set.primary_file)
      }
    end
  end

  def link_label
    if viewer_enabled?
      "View digital content"
    else
      "Download content"
    end
  end

  private

    def build_type
      if viewer_enabled?
        "html"
      else
        "link"
      end
    end

    def build_media_type
      if !viewer_enabled?
        "Download"
      elsif mosaic?
        "Mosaic"
      elsif file_set&.video?
        "Video"
      elsif file_set&.audio?
        "Audio"
      else
        "Image"
      end
    end

    def build_content
      if viewer_enabled?
        build_iframe
      else
        # download the first file set
        helper.download_url(file_set, file_set.primary_file)
      end
    end

    def helper
      @helper ||= ManifestBuilder::ManifestHelper.new
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

    def unauthorized_status
      if ability.current_user.anonymous?
        # They don't have permission to see it, but could anonymously if they
        # did something - probably go on VPN.
        if anonymously_authorizable?
          "unauthorized"
        else
          "unauthenticated"
        end
      elsif ability.can?(:discover, resource)
        # If they can discover it, then it's probably a CDL resource - given
        # some action they can get it
        "unauthorized"
      else
        # If they can't even discover it, there's nothing they can do. They're
        # explicitly forbidden.
        "forbidden"
      end
    end

    # Returns true if a resource can be viewed anonymously, but the person is
    # not in a circumstance where they're authorized to - e.g. it's a campus
    # only resource, and they're not on campus or VPN.
    def anonymously_authorizable?
      resource.visibility.include?(::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ON_CAMPUS)
    end

    def viewer_enabled?
      !(file_set&.mime_type || []).include?("application/zip")
    end

    def file_set
      @file_set ||= Wayfinder.for(resource).file_sets.first
    end

    def mosaic?
      return false unless resource.is_a?(RasterResource) || resource.is_a?(ScannedMap)
      resource.decorate.mosaic_file_count > 1
    end
end
