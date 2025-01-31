# frozen_string_literal: true
class ManifestBuilderV3
  # See: https://iiif.io/api/presentation/3.0/#rendering
  class RenderingBuilder < ManifestBuilder::RenderingBuilder
    def apply(manifest)
      (manifest["rendering"] ||= []) << catalog_rendering_hash if identifier?
      manifest
    end

    private

      def catalog_rendering_hash
        {
          "id" => Ark.new(identifier).uri,
          "format" => "text/html",
          "type" => "Text",
          "label" => { "en": ["View in catalog"] }
        }
      end
  end
end
