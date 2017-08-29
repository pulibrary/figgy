# frozen_string_literal: true
require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver(:headless_chrome) do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu disable-setuid-sandbox) }
  )

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities)
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_max_wait_time = 15
Capybara.default_driver = :selenium
