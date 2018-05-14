# frozen_string_literal: true
class ManifestBuilder
  class LogoBuilder
    attr_reader :resource

    ##
    # @param [Valhalla::Resource] resource the Resource being viewed
    def initialize(record)
      @record = record
      protocol = /localhost/.match?(Figgy.default_url_options[:host]) ? "http" : "https"
      @host = "#{protocol}://#{Figgy.default_url_options[:host]}"
    end

    def apply(manifest)
      manifest["logo"] = ActionController::Base.helpers.image_url(logo, host: @host)
      manifest
    end

    private

      def logo
        if @record.resource.respond_to?(:rights_statement) && @record.resource.rights_statement.include?(RDF::URI("http://cicognara.org/microfiche_copyright"))
          "vatican.png"
        else
          "pul_logo_icon.png"
        end
      end
  end
end
