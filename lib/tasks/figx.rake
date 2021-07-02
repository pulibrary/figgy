# frozen_string_literal: true

require_relative "../../spec/support/create_for_repository"

namespace :figx do
  task seed: :environment do
    raise unless Rails.env.test?
    DataSeeder.new.wipe_metadata!
    FactoryBot.create_for_repository(
      :collection,
      id: "597edce8-3a2f-41cd-be2b-182dae7b9a8f",
      title: "Test Collection",
      description: "Test Description",
      slug: "studentperf",
      identifier: ["ark:/88435/0p096g241", "broken"]
    )
    FactoryBot.create_for_repository(
      :collection,
      id: "868e05da-53b9-483b-8b6b-2d115becce84",
      title: "No Identifier Collection",
      description: "Collection with no ARK",
      slug: "noark"
    )
    FactoryBot.create_for_repository(:scanned_resource, id: "abd5f5a2-7caa-435a-924e-d5982b0a6260")
    FactoryBot.create_for_repository(
      :scanned_resource,
      id: "cad0a459-e520-442d-9139-c338bd60af6f",
      member_of_collection_ids: [Valkyrie::ID.new("597edce8-3a2f-41cd-be2b-182dae7b9a8f")],
      imported_metadata: [{
        title: ["Concert, 2012, April 07"],
        description: ["A complete program is available in Mendel Music Library."]
      }]
    )
    FactoryBot.create_for_repository(
      :ephemera_folder,
      id: "02f7dad6-cbaa-47e8-913e-b89bdd16bb17",
      member_of_collection_ids: [Valkyrie::ID.new("597edce8-3a2f-41cd-be2b-182dae7b9a8f")],
      title: ["Ephemera Folder"],
      description: ["I'm ephemera."]
    )
  end
end
