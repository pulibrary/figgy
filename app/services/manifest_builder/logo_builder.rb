# frozen_string_literal: true
class ManifestBuilder
  class LogoBuilder
    attr_reader :resource

    ##
    # @param [Resource] resource the Resource being viewed
    def initialize(record)
      @record = record
    end

    def apply(manifest)
      manifest["logo"] = logo_url
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
  end
end
