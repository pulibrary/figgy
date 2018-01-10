# frozen_string_literal: true
class ManifestBuilder
  class SequenceBuilder < IIIFManifest::ManifestBuilder::SequenceBuilder
    def apply(manifest)
      sequence["viewingHint"] = manifest["viewingHint"]
      super
    end
  end
end
