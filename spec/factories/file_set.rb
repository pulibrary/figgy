# frozen_string_literal: true
FactoryBot.define do
  factory :file_set do
    sequence(:title) { |x| "File Set #{x}" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      user nil
    end
    after(:build) do |resource, evaluator|
      resource.depositor = evaluator.user.uid if evaluator.user.present?
    end

    factory :geo_metadata_file_set do
      file_metadata FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_metadata_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile)
    end

    factory :zip_file_set do
      file_metadata FileMetadata.new(mime_type: "application/zip", use: Valkyrie::Vocab::PCDMUse.OriginalFile, id: SecureRandom.uuid)
    end

    factory :geo_image_file_set do
      file_metadata FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_image_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile)
    end

    factory :geo_raster_file_set do
      file_metadata FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_raster_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile)
    end

    factory :geo_vector_file_set do
      file_metadata FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_vector_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile)
    end

    factory :intermediate_image_file_set do
      file_metadata FileMetadata.new(mime_type: "image/tiff", use: Valkyrie::Vocab::PCDMUse.IntermediateFile)
    end

    factory :audio_file_set do
      file_metadata [
        FileMetadata.new(mime_type: "audio/x-wav", use: Valkyrie::Vocab::PCDMUse.PreservationMasterFile, id: "original"),
        FileMetadata.new(mime_type: "audio/mp3", use: Valkyrie::Vocab::PCDMUse.ServiceFile, id: "derivative"),
        FileMetadata.new(mime_type: "audio/x-wav", use: Valkyrie::Vocab::PCDMUse.IntermediateFile, id: "intermediate")
      ]
    end
  end
end
