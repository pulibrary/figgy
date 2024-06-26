# frozen_string_literal: true
FactoryBot.define do
  factory :file_set do
    sequence(:title) { |x| "File Set #{x}" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      user { nil }
    end
    after(:build) do |resource, evaluator|
      resource.depositor = evaluator.user.uid if evaluator.user.present?
    end

    factory :original_file_file_set do
      file_metadata { FileMetadata.new(use: ::PcdmUse::OriginalFile) }
    end

    factory :original_image_file_set do
      file_metadata { FileMetadata.new(use: ::PcdmUse::OriginalFile, mime_type: "image/tiff") }
    end

    factory :geo_metadata_file_set do
      file_metadata { FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_metadata_format).all.first.value, use: ::PcdmUse::OriginalFile) }
    end

    factory :zip_file_set do
      file_metadata { FileMetadata.new(mime_type: "application/zip", use: ::PcdmUse::OriginalFile, id: SecureRandom.uuid) }
    end

    factory :geo_image_file_set do
      file_metadata { FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_image_format).all.first.value, use: ::PcdmUse::OriginalFile) }
    end

    factory :geo_raster_file_set do
      file_metadata { FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_raster_format).all.first.value, use: ::PcdmUse::OriginalFile) }
    end

    factory :geo_vector_file_set do
      file_metadata { FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_vector_format).all.first.value, use: ::PcdmUse::OriginalFile) }
    end

    factory :geo_raster_cloud_file do
      file_metadata do
        [
          FileMetadata.new(
            id: Valkyrie::ID.new(SecureRandom.uuid),
            mime_type: "image/tiff; gdal-format=GTiff",
            use: ::PcdmUse::CloudDerivative,
            original_filename: "display_raster.tif",
            file_identifiers: ["cloud-geo-derivatives-shrine://#{Figgy.config['cloud_geo_bucket']}/example.tif"]
          ),
          FileMetadata.new(id: Valkyrie::ID.new(SecureRandom.uuid), mime_type: "image/tiff; gdal-format=GTiff", use: ::PcdmUse::OriginalFile)
        ]
      end
      service_targets { "tiles" }
    end

    factory :intermediate_image_file_set do
      file_metadata { FileMetadata.new(mime_type: "image/tiff", use: ::PcdmUse::IntermediateFile) }
    end

    factory :audio_file_set do
      file_metadata do
        [
          FileMetadata.new(mime_type: "audio/x-wav", use: ::PcdmUse::PreservationFile, id: "original"),
          FileMetadata.new(mime_type: "audio/mp3", use: ::PcdmUse::ServiceFile, id: "derivative"),
          FileMetadata.new(mime_type: "audio/x-wav", use: ::PcdmUse::IntermediateFile, id: "intermediate")
        ]
      end
    end

    factory :video_file_set do
      file_metadata do
        [
          FileMetadata.new(mime_type: "video/mp4", use: ::PcdmUse::OriginalFile, id: "original"),
          FileMetadata.new(mime_type: "application/x-mpegURL", use: ::PcdmUse::ServiceFile, id: "derivative"),
          FileMetadata.new(mime_type: "video/MP2T", use: ::PcdmUse::ServiceFilePartial, id: "derivative-partial")
        ]
      end
    end

    factory :video_file_set_with_caption do
      file_metadata do
        [
          FileMetadata.new(mime_type: "video/mp4", use: ::PcdmUse::OriginalFile, id: "original"),
          FileMetadata.new(mime_type: "application/x-mpegURL", use: ::PcdmUse::ServiceFile, id: "derivative"),
          FileMetadata.new(mime_type: "video/MP2T", use: ::PcdmUse::ServiceFilePartial, id: "derivative-partial"),
          FileMetadata.new(mime_type: "text/vtt", use: ::PcdmUse::Caption, id: "caption", original_language_caption: true, file_identifiers: [Valkyrie::ID.new("storageid")])
        ]
      end
    end

    factory :video_file_set_with_other_language_caption do
      file_metadata do
        [
          FileMetadata.new(mime_type: "video/mp4", use: ::PcdmUse::OriginalFile, id: "original"),
          FileMetadata.new(mime_type: "application/x-mpegURL", use: ::PcdmUse::ServiceFile, id: "derivative"),
          FileMetadata.new(mime_type: "video/MP2T", use: ::PcdmUse::ServiceFilePartial, id: "derivative-partial"),
          FileMetadata.new(mime_type: "text/vtt", use: ::PcdmUse::Caption, id: "caption", file_identifiers: [Valkyrie::ID.new("storageid")])
        ]
      end
    end

    factory :pdf_file_set do
      file_metadata do
        [
          FileMetadata.new(mime_type: "application/pdf", use: ::PcdmUse::PreservationFile, id: "original"),
          FileMetadata.new(mime_type: "image/tiff", use: ::PcdmUse::IntermediateFile, id: "intermediate")
        ]
      end
    end
  end
end
