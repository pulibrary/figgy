# frozen_string_literal: true

# Monkey patch the language_map method so that the language is set in IIIF
# Presentation 3 manifests.
# See: https://github.com/samvera/iiif_manifest/blob/main/lib/iiif_manifest/v3/manifest_builder.rb#L31
class IIIFManifest::V3::ManifestBuilder
  def self.obj_to_language_map(obj)
    if obj.is_a?(Array) && obj.first.is_a?(RDF::Literal)
      language = obj.first.language.to_s
      { language.to_s => obj.map(&:to_s) }
    else
      { "eng" => Array(obj) }
    end
  end
end
