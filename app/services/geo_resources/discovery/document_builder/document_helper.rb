# frozen_string_literal: true
module GeoResources
  module Discovery
    class DocumentBuilder
      class DocumentHelper
        include Rails.application.routes.url_helpers
        include ActionDispatch::Routing::PolymorphicRoutes
      end
    end
  end
end
