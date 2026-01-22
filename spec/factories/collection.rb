FactoryBot.define do
  factory :collection do
    title { "Title" }
    slug { "test" }
    publish { true }
    description { "description" }
    visibility { "open" }
    read_groups { "public" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    factory :private_collection do
      visibility { "private" }
    end
    factory :archival_media_collection do
      change_set { "archival_media_collection" }
    end
  end
end
