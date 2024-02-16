# frozen_string_literal: true
require "capybara/rspec"
require "selenium-webdriver"

Capybara.server_host = '0.0.0.0'
Capybara.always_include_port = true
if !ENV["CI"]
  Capybara.app_host = "http://host.docker.internal:#{Capybara.server_port}"
else
  # In CI all the ports from containers are on localhost.
  Capybara.app_host = "http://127.0.0.1:#{Capybara.server_port}"
end

Capybara.register_driver(:selenium) do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu disable-setuid-sandbox window-size=1920,1080]
  )
  browser_options.add_argument("--headless") unless ENV["RUN_IN_BROWSER"] == "true"
  browser_options.add_argument("--disable-gpu")

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 120
  http_client.open_timeout = 120
  Capybara::Selenium::Driver.new(app,
                                 browser: :remote,
                                 options: browser_options,
                                 http_client: http_client,
                                 url: "http://127.0.0.1:4444/wd/hub")
end

Capybara.javascript_driver = :selenium
Capybara.default_max_wait_time = 15
