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
      file_metadata { FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.OriginalFile) }
    end

    factory :original_image_file_set do
      file_metadata { FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.OriginalFile, mime_type: "image/tiff") }
    end

    factory :geo_metadata_file_set do
      file_metadata { FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_metadata_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile) }
    end

    factory :zip_file_set do
      file_metadata { FileMetadata.new(mime_type: "application/zip", use: Valkyrie::Vocab::PCDMUse.OriginalFile, id: SecureRandom.uuid) }
    end

    factory :geo_image_file_set do
      file_metadata { FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_image_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile) }
    end

    factory :geo_raster_file_set do
      file_metadata { FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_raster_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile) }
    end

    factory :geo_vector_file_set do
      file_metadata { FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_vector_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile) }
    end

    factory :geo_raster_cloud_file do
      file_metadata do
        [
          FileMetadata.new(
            id: Valkyrie::ID.new(SecureRandom.uuid),
            mime_type: "image/tiff; gdal-format=GTiff",
            use: Valkyrie::Vocab::PCDMUse.CloudDerivative,
            original_filename: "display_raster.tif",
            file_identifiers: ["cloud-geo-derivatives-shrine://#{Figgy.config['cloud_geo_bucket']}/example.tif"]
          ),
          FileMetadata.new(id: Valkyrie::ID.new(SecureRandom.uuid), mime_type: "image/tiff; gdal-format=GTiff", use: Valkyrie::Vocab::PCDMUse.OriginalFile)
        ]
      end
      service_targets { "tiles" }
    end

    factory :intermediate_image_file_set do
      file_metadata { FileMetadata.new(mime_type: "image/tiff", use: Valkyrie::Vocab::PCDMUse.IntermediateFile) }
    end

    factory :audio_file_set do
      file_metadata do
        [
          FileMetadata.new(mime_type: "audio/x-wav", use: Valkyrie::Vocab::PCDMUse.PreservationFile, id: "original"),
          FileMetadata.new(mime_type: "audio/mp3", use: Valkyrie::Vocab::PCDMUse.ServiceFile, id: "derivative"),
          FileMetadata.new(mime_type: "audio/x-wav", use: Valkyrie::Vocab::PCDMUse.IntermediateFile, id: "intermediate")
        ]
      end
    end

    factory :pdf_file_set do
      file_metadata do
        [
          FileMetadata.new(mime_type: "application/pdf", use: Valkyrie::Vocab::PCDMUse.PreservationFile, id: "original"),
          FileMetadata.new(mime_type: "image/tiff", use: Valkyrie::Vocab::PCDMUse.IntermediateFile, id: "intermediate")
        ]
      end
    end
  end
end
