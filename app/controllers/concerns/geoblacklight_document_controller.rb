module GeoblacklightDocumentController
  extend ActiveSupport::Concern

  included do
    def geoblacklight
      respond_to do |f|
        f.json do
          render json: geoblacklight_builder
        end
      end
    end

    def aardvark
      respond_to do |f|
        f.json do
          render json: aardvark_builder
        end
      end
    end
  end

  private

    def geoblacklight_builder
      @resource = find_resource(params[:id])
      @geoblacklight_builder ||= GeoDiscovery::DocumentBuilder.new(@resource, GeoDiscovery::GeoblacklightDocument.new)
    end

    def aardvark_builder
      @resource = find_resource(params[:id])
      @aardvark_builder ||= GeoDiscovery::DocumentBuilder.new(@resource, GeoDiscovery::GeoblacklightAardvarkDocument.new)
    end
end
