# frozen_string_literal: true

require_relative "../../spec/support/create_for_repository"

namespace :figx do
  task seed: :environment do
    raise unless Rails.env.test?
    DataSeeder.new.wipe_metadata!
    FactoryBot.create_for_repository(:collection, id: "597edce8-3a2f-41cd-be2b-182dae7b9a8f")
  end
end
