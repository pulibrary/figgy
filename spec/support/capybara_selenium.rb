# frozen_string_literal: true
require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver(:headless_chrome) do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu disable-setuid-sandbox window-size=7680,4320) }
  )

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.timeout = 120
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities,
                                 http_client: http_client)
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_max_wait_time = 15
Capybara.default_driver = :selenium
