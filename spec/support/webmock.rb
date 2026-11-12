require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true,
                             allow: ["chromedriver.storage.googleapis.com", "solr"],
                             net_http_connect_on_start: %w[localhost 127.0.0.1])
ENV["NO_PROXY"] = nil
