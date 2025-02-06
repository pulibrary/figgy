# frozen_string_literal: true
class ManifestBuilderV3
  # This class makes one small changes from ManifestBuilder::LogoBuilder, but we
  # do not inherit from that class because it will likely be deleted as part of
  # the work for https://github.com/pulibrary/figgy/issues/5747
  class ProviderBuilder
    attr_reader :resource

    ##
    # @param [Resource] resource the Resource being viewed
    def initialize(record)
      @record = record
    end

    def apply(manifest)
      manifest["provider"] = [provider]
      manifest
    end

    private

      def resource_logo
        Array.wrap(@record.resource.rights_statement)
      end

      def logo_file
        if @record.resource.respond_to?(:rights_statement) && resource_logo.include?(RDF::URI("http://cicognara.org/microfiche_copyright"))
          "vatican.png"
        else
          "pul_logo_icon.png"
        end
      end

      def logo_url
        protocol = /localhost/.match?(Figgy.default_url_options[:host]) ? "http" : "https"
        "#{protocol}://#{Figgy.default_url_options[:host]}/#{logo_file}"
      end

      def logo
        {
          "id" => logo_url,
          "type" => "Image",
          "format" => "image/png",
          "height" => 100,
          "width" => 120
        }
      end

      def provider
        {
          "id": "https://library.princeton.edu",
          "type": "Agent",
          "label": {
            "en": [
              "Princeton University Library"
            ]
          },
          "logo": [logo]
        }
      end
  end
end
