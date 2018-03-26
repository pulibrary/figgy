# frozen_string_literal: true
class ManifestBuilder
  class LogoBuilder
    attr_reader :resource

    ##
    # @param [Valhalla::Resource] resource the Resource being viewed
    def initialize(record)
      @record = record
      @host = "https://#{Figgy.default_url_options[:host]}"
    end

    def apply(manifest)
      manifest["logo"] = ActionController::Base.helpers.image_url(logo, host: @host)
      manifest
    end

    private

      def logo
        'pul_logo_icon.png'
      end
  end
end
