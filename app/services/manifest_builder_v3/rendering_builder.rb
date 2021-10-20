# frozen_string_literal: true
class ManifestBuilderV3
  # See: https://iiif.io/api/presentation/3.0/#rendering
  class RenderingBuilder < ManifestBuilder::RenderingBuilder
    def apply(manifest)
      # This is currently here to work around https://github.com/iiif-prezi/osullivan/issues/56
      manifest["rendering"] << rendering_hash if identifier?
      manifest
    end

    private

      def rendering_hash
        {
          "id" => Ark.new(identifier).uri,
          "format" => "text/html",
          "type" => "Text",
          "label" => { "en": ["View in catalog"] }
        }
      end
  end
end
