# frozen_string_literal: true
FactoryBot.define do
  factory :numismatic_artist, class: Numismatics::Artist do
    signature { "signature" }
    role { "artist" }
    side { "obverse" }

    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
