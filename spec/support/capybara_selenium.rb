# frozen_string_literal: true
require "capybara/rspec"
require "selenium-webdriver"

# there's a bug in capybara-screenshot that requires us to name
#   the driver ":selenium" so we changed it from :headless_chrome"
Capybara.register_driver(:selenium) do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[headless disable-gpu disable-setuid-sandbox window-size=7680,4320] }
  )
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << "--headless"
  browser_options.args << "--disable-gpu"

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 120
  http_client.open_timeout = 120
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities,
                                 http_client: http_client,
                                 options: browser_options)
end

Capybara.javascript_driver = :selenium
Capybara.default_max_wait_time = 15
