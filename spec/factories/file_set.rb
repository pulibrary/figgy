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

    factory :geo_raster_file_set do
      file_metadata FileMetadata.new(mime_type: ControlledVocabulary.for(:geo_raster_format).all.first.value, use: Valkyrie::Vocab::PCDMUse.OriginalFile)
    end
  end
end
