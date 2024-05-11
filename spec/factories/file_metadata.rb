# frozen_string_literal: true

# You can't create these but you can build them.
FactoryBot.define do
  factory :file_metadata do
    factory :image_derivative do
      id { Valkyrie::ID.new(SecureRandom.uuid) }
      mime_type { "image/tiff" }
      use { ::PcdmUse::ServiceFile }
    end

    factory :image_thumbnail do
      id { Valkyrie::ID.new(SecureRandom.uuid) }
      mime_type { "image/tiff" }
      use { ::PcdmUse::ThumbnailImage }
    end

    factory :image_original do
      id { Valkyrie::ID.new(SecureRandom.uuid) }
      mime_type { "image/tiff" }
      use { ::PcdmUse::OriginalFile }
    end

    factory :vector_original do
      id { Valkyrie::ID.new(SecureRandom.uuid) }
      mime_type { "application/vnd.geo+json" }
      use { ::PcdmUse::OriginalFile }
    end

    factory :cloud_vector_derivative do
      id { Valkyrie::ID.new(SecureRandom.uuid) }
      mime_type { "application/vnd.pmtiles" }
      use { ::PcdmUse::CloudDerivative }
    end
  end
end
