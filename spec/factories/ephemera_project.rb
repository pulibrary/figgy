FactoryBot.define do
  factory :ephemera_project do
    title { "Test Project" }
    slug { "test_project-1234" }
    publish { true }
    tagline { "project tagline" }
    description { "project extended description" }
    banner_image_url { "https://iiif-cloud.princeton.edu/iiif/2/60%2Fb5%2Fe5%2F60b5e5365600450db52dbe4d7f92b8cc%2Fintermediate_file/642,2316,3854,2569/750,/0/default.jpg" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
