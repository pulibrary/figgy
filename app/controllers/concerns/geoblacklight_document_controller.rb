# frozen_string_literal: true

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
  end

  private

    def geoblacklight_document_class
      GeoDiscovery::GeoblacklightDocument
    end

    def geoblacklight_builder
      @resource = find_resource(params[:id])
      @geoblacklight_builder ||= GeoDiscovery::DocumentBuilder.new(@resource, geoblacklight_document_class.new)
    end
end
