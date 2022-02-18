# frozen_string_literal: true

class ManifestBuilder
  class ImageBuilder < IIIFManifest::ManifestBuilder::ImageBuilder
    # Add an id. the only data we have is what we pull out of the canvas and other hashes.
    #   Use the canvas id since we know it references the fileset.
    def apply(canvas)
      annotation["@id"] = canvas["@id"].sub(/(.*)canvas/, '\1image')
      super
    end
  end
end
