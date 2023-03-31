# frozen_string_literal: true
ENV["RACK_ENV"] = "test"

require File.expand_path("../../config/environment", __FILE__)
abort("DATABASE_URL environment variable is set") if ENV["DATABASE_URL"]

require "rspec/rails"
require Rails.root.join("spec", "shared_specs.rb")
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |file| require file }

Capybara.server = :puma, { Silent: true }

module Features
  # Extend this module in spec/support/features/*.rb
  include Formulaic::Dsl
end

RSpec.configure do |config|
  config.include Features, type: :feature
  # Use local fixture_file_with_use method
  config.include FixtureFileWithUse
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.file_fixture_path = "#{::Rails.root}/spec/fixtures"

  # Prevent leaking view contexts between tests
  # see https://github.com/drapergem/draper/issues/814
  # see https://github.com/drapergem/draper/issues/655
  config.before { Draper::ViewContext.clear! }
  config.after { Draper::ViewContext.clear! }
end

ActiveRecord::Migration.maintain_test_schema!
