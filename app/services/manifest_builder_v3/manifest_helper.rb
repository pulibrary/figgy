class ManifestBuilderV3
  # Class providing helper methods for the IIIF::Presentation::Manifest
  class ManifestHelper
    include ActionDispatch::Routing::PolymorphicRoutes
    include Rails.application.routes.url_helpers

    ##
    # Retrieve the default options for URL's
    # @return [Hash]
    def default_url_options
      Figgy.default_url_options
    end

    def manifest_url(resource)
      "#{protocol}://#{host}/concern/#{resource.model_name.collection}/#{resource.id}/manifest"
    end

    def token_authorizable?(resource)
      resource.respond_to?(:auth_token) && !resource.auth_token.nil?
    end

    def pdf_url(resource)
      url = manifest_url(resource).gsub("manifest", "pdf")
      return url + "?auth_token=#{resource.auth_token}" if token_authorizable?(resource)
      url
    end

    def host
      default_url_options[:host]
    end

    def protocol
      default_url_options[:protocol] || "http"
    end

    ##
    # Retrieve the base URL for Riiif
    # @param [String] id identifier for the image resource
    # @param file_metadata [FileMetadata, nil] the pyramidal derivative
    # @return [String]
    def manifest_image_path(resource, file_metadata = nil)
      if (Rails.env.development? && Figgy.config["pyramidals_bucket"].blank?) || Rails.env.test?
        ManifestBuilder::RiiifHelper.new.base_url(resource.id)
      else
        ManifestBuilder::PyramidalHelper.new.base_url(resource, file_metadata)
      end
    end

    ##
    # Retrieve the URL path for an image served over the Riiif
    # @param [FileSet] resource A FileSet to generate a
    #   thumbnail URL from.
    # @param size [String] IIIF size parameter
    # @param format [String] IIIF output format
    # @return [String]
    def manifest_image_thumbnail_path(resource, size: "!200,150", format: "jpg")
      "#{manifest_image_path(resource, resource.try(:pyramidal_thumbnail))}/full/#{size}/0/default.#{format}"
    end

    def manifest_image_medium_path(resource)
      "#{manifest_image_path(resource)}/full/1000,/0/default.jpg"
    end
  end
end
