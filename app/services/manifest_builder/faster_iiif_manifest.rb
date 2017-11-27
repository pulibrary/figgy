# frozen_string_literal: true
class ManifestBuilder
  class Service
    attr_reader :inner_hash
    def initialize
      @inner_hash = initial_attributes
    end

    delegate :[]=, :[], :as_json, :to_json, to: :inner_hash

    def initial_attributes
      {}
    end
  end

  class FasterIIIFManifest < Service
    def label=(label)
      inner_hash["label"] = label
    end

    def description=(description)
      return unless description.present?
      inner_hash["description"] = description
    end

    def viewing_hint=(viewing_hint)
      return unless viewing_hint.present?
      inner_hash["viewingHint"] = viewing_hint
    end

    def viewing_direction=(viewing_direction)
      return unless viewing_direction.present?
      inner_hash["viewingDirection"] = viewing_direction
    end

    def sequences
      inner_hash["sequences"] || []
    end

    def sequences=(sequences)
      inner_hash["sequences"] = sequences
    end

    def metadata=(metadata)
      inner_hash["metadata"] = metadata
    end

    def see_also=(see_also)
      inner_hash["seeAlso"] = see_also
    end

    def license=(license)
      inner_hash["license"] = license
    end

    def initial_attributes
      {
        "@context" => "http://iiif.io/api/presentation/2/context.json",
        "@type" => "sc:Manifest"
      }
    end

    class Sequence < Service
      def canvases
        inner_hash["canvases"] || []
      end

      def canvases=(canvases)
        inner_hash["canvases"] = canvases
      end

      def initial_attributes
        {
          "@type" => "sc:Sequence"
        }
      end
    end

    class Canvas < Service
      def label=(label)
        inner_hash["label"] = label
      end

      def images
        inner_hash["images"] || []
      end

      def images=(images)
        inner_hash["images"] = images
      end

      def initial_attributes
        {
          "@type" => "sc:Canvas"
        }
      end
    end

    class Range < Service
      def initial_attributes
        {
          "@type" => "sc:Range"
        }
      end
    end

    class Resource < Service
      def service=(service)
        inner_hash['service'] = service
      end

      def initial_attributes
        {
          "@type" => "sc:Range"
        }
      end
    end

    class Annotation < Service
      def resource=(resource)
        inner_hash["resource"] = resource
      end

      def resource
        inner_hash["resource"]
      end

      def initial_attributes
        {
          "@type" => "oa:Annotation",
          "motivation" => "sc:painting"
        }
      end
    end
  end
end
