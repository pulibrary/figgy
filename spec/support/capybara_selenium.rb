# frozen_string_literal: true
require "capybara/rspec"
require "selenium-webdriver"

# there's a bug in capybara-screenshot that requires us to name
#   the driver ":selenium" so we changed it from :headless_chrome"
selenium_url = nil
browser = :chrome
# If we're not in CI then run Selenium from Lando. Makes it much easier to
# upgrade versions of Chrome.
Capybara.server_host = '0.0.0.0'
Capybara.always_include_port = true
Capybara.app_host = "http://host.docker.internal:#{Capybara.server_port}"
browser = :remote
if !ENV["CI"]
  selenium_url = "http://127.0.0.1:4445/wd/hub"
else
  selenium_url = "http://127.0.0.1:4444/wd/hub"
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
                                 browser: browser,
                                 options: browser_options,
                                 http_client: http_client,
                                 url: selenium_url)
end

Capybara.javascript_driver = :selenium
Capybara.default_max_wait_time = 15
