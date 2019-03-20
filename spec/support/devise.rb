# frozen_string_literal: true
require_relative 'request_spec_helper'
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :helper
  config.include RequestSpecHelper, type: :request
end
