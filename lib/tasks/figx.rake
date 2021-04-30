# frozen_string_literal: true

require_relative "../../spec/support/create_for_repository"

namespace :figx do
  task seed: :environment do
    raise unless Rails.env.test?
    DataSeeder.new.wipe_metadata!
    FactoryBot.create_for_repository(:collection, id: "597edce8-3a2f-41cd-be2b-182dae7b9a8f", title: "Test Collection")
    FactoryBot.create_for_repository(:scanned_resource, id: "abd5f5a2-7caa-435a-924e-d5982b0a6260")
  end
end
