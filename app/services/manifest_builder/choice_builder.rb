# frozen_string_literal: true
class ManifestBuilder
  class ChoiceBuilder < IIIFManifest::V3::ManifestBuilder::ChoiceBuilder
    def apply(canvas)
      annotation["target"] = canvas["id"]
      first_choice = choice.items.first
      unless first_choice.nil?
        canvas["width"] = first_choice["width"]
        canvas["height"] = first_choice["height"]
        canvas["duration"] = first_choice["duration"]
      end
      annotation.body = choice
      # Assume first item in canvas is an annotation page
      canvas.items.first.items += [annotation]
    end
  end
end
