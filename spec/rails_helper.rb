ENV["RACK_ENV"] = "test"
require "simplecov"
if ENV["CIRCLE_ARTIFACTS"]
  dir = File.join(ENV["CIRCLE_ARTIFACTS"], "coverage")
  SimpleCov.coverage_dir(dir)
end
SimpleCov.start "rails"

require File.expand_path("../../config/environment", __FILE__)
abort("DATABASE_URL environment variable is set") if ENV["DATABASE_URL"]

require "rspec/rails"
require Rails.root.join("spec", "shared_specs.rb")
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |file| require file }

Capybara.server = :puma, { Silent: true }

# Ensure sidekiq jobs aren't added to redis during tests
# note this puts Sidekiq in "fake" mode by default
require "sidekiq/testing"
require "axe-rspec"

module Features
  # Extend this module in spec/support/features/*.rb
  include Formulaic::Dsl
end

RSpec.configure do |config|
  config.include Features, type: :feature
  config.include ActionCable::TestHelper
  # Use local fixture_file_with_use method
  config.include FixtureFileWithUse
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
  config.file_fixture_path = "#{::Rails.root}/spec/fixtures"

  # Prevent leaking view contexts between tests
  # see https://github.com/drapergem/draper/issues/814
  # see https://github.com/drapergem/draper/issues/655
  config.before { Draper::ViewContext.clear! }
  config.after { Draper::ViewContext.clear! }

  # Clear Sidekiq Jobs between tests
  config.before { Sidekiq::Worker.clear_all }
  config.after { Sidekiq::Worker.clear_all }
end

ActiveRecord::Migration.maintain_test_schema!
