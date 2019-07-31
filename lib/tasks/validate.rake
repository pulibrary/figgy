# frozen_string_literal: true
namespace :validate do
  task mets: :environment do
    dir = ENV["DIR"]
    validator = MetsValidator.new(Valkyrie.config.metadata_adapter.query_service)
    Dir["#{dir}/**/*.mets"].each do |f|
      validator.validate(f)
    end
  end
end
