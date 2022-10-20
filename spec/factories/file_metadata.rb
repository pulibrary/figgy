# frozen_string_literal: true

# You can't create these but you can build them.
FactoryBot.define do
  factory :file_metadata do
    factory :image_derivative do
      id { Valkyrie::ID.new(SecureRandom.uuid) }
      mime_type { "image/tiff" }
      use { Valkyrie::Vocab::PCDMUse.ServiceFile }
    end

    factory :image_thumbnail do
      id { Valkyrie::ID.new(SecureRandom.uuid) }
      mime_type { "image/tiff" }
      use { Valkyrie::Vocab::PCDMUse.ThumbnailImage }
    end

    factory :image_original do
      id { Valkyrie::ID.new(SecureRandom.uuid) }
      mime_type { "image/tiff" }
      use { Valkyrie::Vocab::PCDMUse.OriginalFile }
    end
  end
end
