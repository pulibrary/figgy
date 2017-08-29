# frozen_string_literal: true
require 'capybara/rails'
require 'capybara/rspec'
RSpec.configure do |config|
  config.include Capybara::RSpecMatchers, type: :request
end
Capybara.raise_server_errors = false
