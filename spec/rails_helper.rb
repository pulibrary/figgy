# frozen_string_literal: true
ENV["RACK_ENV"] = "test"
require "simplecov"

SimpleCov.start "rails"

require File.expand_path("../../config/environment", __FILE__)
abort("DATABASE_URL environment variable is set") if ENV["DATABASE_URL"]

require "rspec/rails"
require Rails.root.join("spec", "shared_specs.rb")
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |file| require file }

module Features
  # Extend this module in spec/support/features/*.rb
  include Formulaic::Dsl
end

RSpec.configure do |config|
  config.include Features, type: :feature
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
end

ActiveRecord::Migration.maintain_test_schema!
