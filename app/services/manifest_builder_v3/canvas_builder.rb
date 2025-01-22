# frozen_string_literal: true
class ManifestBuilderV3
  class CanvasBuilder < IIIFManifest::V3::ManifestBuilder::CanvasBuilder
    def apply_record_properties
      super
      canvas["local_identifier"] = record.local_identifier.first if record.try(:local_identifier).present?
      canvas["viewingHint"] = record.viewing_hint.first if record.try(:viewing_hint).present?
      canvas["accompanyingCanvas"] = accompanying_canvas
      rendering_builder.new(record).apply(canvas)
    end

    def apply(sequence)
      return sequence if record.resource.mime_type.include?("application/pdf")
      super
    end

    def rendering_builder
      ManifestBuilderV3::CanvasRenderingBuilder
    end

    def label
      return record.structure.label if record.respond_to?(:structure)
      record.try(:label)
    end

    def accompanying_canvas
      {
        "type" => "Canvas",
        "id" => "http://localhost:3000/concern/scanned_resources/bcec3b91-9a8d-4081-a483-129a48afb135/manifest/canvas/15681461-69dc-47cc-a8bc-85df5118d023",
        "label" => {
          "eng" => [
            "32101047382484_AssetFront.jpg"
          ]
        },
        "items" => [
          {
            "type" => "AnnotationPage",
            "id" => "http://localhost:3000/concern/scanned_resources/bcec3b91-9a8d-4081-a483-129a48afb135/manifest/canvas/15681461-69dc-47cc-a8bc-85df5118d023/annotation_page/706c6dd1-29ad-4d59-af55-472949534a8b",
            "items" => [
              {
                "type" => "Annotation",
                "motivation" => "painting",
                "body" => {
                  "id" => "http://localhost:3000/image-service/15681461-69dc-47cc-a8bc-85df5118d023/full/1000,/0/default.jpg",
                  "type" => "Image",
                  "height" => 1728,
                  "width" => 2592,
                  "format" => "image/jpeg",
                  "service" => [
                    {
                      "id" => "http://localhost:3000/image-service/15681461-69dc-47cc-a8bc-85df5118d023",
                      "profile" => "http://iiif.io/api/image/2/level2.json",
                      "type" => "ImageService2"
                    }
                  ]
                },
                "target" => "http://localhost:3000/concern/scanned_resources/bcec3b91-9a8d-4081-a483-129a48afb135/manifest/canvas/15681461-69dc-47cc-a8bc-85df5118d023"
              }
            ]
          }
        ]
      }
    end

  end
end
