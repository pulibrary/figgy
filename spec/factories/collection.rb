FactoryBot.define do
  factory :collection do
    title { "Title" }
    slug { "test" }
    publish { true }
    description { "description" }
    visibility { "open" }
    read_groups { "public" }
    tagline { "the coolest stuff we could find on this topic" }
    banner_image_url { "https://iiif-cloud.princeton.edu/iiif/2/60%2Fb5%2Fe5%2F60b5e5365600450db52dbe4d7f92b8cc%2Fintermediate_file/642,2316,3854,2569/full/0/default.jpg" }
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
