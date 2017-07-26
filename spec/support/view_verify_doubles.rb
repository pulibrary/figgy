# frozen_string_literal: true
RSpec.configure do |config|
  config.around(:each, type: :view) do |ex|
    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = false
      ex.run
      mocks.verify_partial_doubles = true
    end
  end
end
