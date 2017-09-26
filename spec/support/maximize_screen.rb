# frozen_string_literal: true
RSpec.configure do |config|
  config.before(:each, js: true) do
    page.driver.browser.manage.window.resize_to(7680, 4320)
  end
 end
 
