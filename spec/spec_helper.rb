# frozen_string_literal: true

require "simplecov"
if ENV["CIRCLE_ARTIFACTS"]
  dir = File.join(ENV["CIRCLE_ARTIFACTS"], "coverage")
  SimpleCov.coverage_dir(dir)
end
SimpleCov.start "rails"

require "webmock/rspec"

# http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.order = :random

  # Cleanup test files and derivatives
  config.after(:suite) do
    break unless Rails.env.test?
    FileUtils.rm_rf(Figgy.config["derivative_path"])
    FileUtils.rm_rf(Figgy.config["geo_derivative_path"])
    FileUtils.rm_rf(Figgy.config["repository_path"])
  end
end

WebMock.disable_net_connect!(allow_localhost: true,
  allow: "chromedriver.storage.googleapis.com")
ENV["NO_PROXY"] = nil
