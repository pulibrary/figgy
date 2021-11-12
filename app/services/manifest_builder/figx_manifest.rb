# frozen_string_literal: true

class ManifestBuilder
  class FigxManifest
    attr_reader :resource
    def initialize(resource)
      @resource =  resource
    end

    def to_json
      Faraday.get("http://localhost:4000/manifest/#{resource.id}").body
    end
  end
end
