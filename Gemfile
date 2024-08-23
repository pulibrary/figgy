# frozen_string_literal: true
source "https://rubygems.org"

gem "aasm"
# TODO: Get rid of this we don't use it.
gem "active-fedora", github: "samvera/active_fedora", branch: "main"
gem "arabic-letter-connector"
gem "archivesspace-client"
gem "autoprefixer-rails"
gem "aws-sdk-s3"
gem "bagit", "~> 0.4"
# Pin to prevent passenger error
gem "base64", "0.1.1"
gem "blacklight", "~> 7.33"
gem "blacklight_iiif_search", "~> 2.1.0"
gem "blacklight_range_limit"
gem "bootsnap", require: false
gem "bootstrap", "~> 4.0"
gem "bootstrap_form", "~> 4.5.0"
gem "bunny"
gem "capistrano-passenger"
gem "capistrano-rails"
gem "capistrano-rails-console"
gem "cocoon"
gem "coffee-rails"
gem "dalli"
gem "ddtrace"
gem "devise", ">= 4.6.0"
gem "devise-guests", git: "https://github.com/cbeer/devise-guests.git"
gem "dnsruby"
gem "draper"
gem "ezid-client", "1.9.4" # v1.9.0 introduces response errors in our tests/stubbing
gem "faker"
gem "ffi", "~> 1.16.0"
gem "filewatcher", "~> 1.0"
gem "flutie"
gem "font-awesome-rails"
gem "google-cloud-pubsub"
# This breaks PreserveResourceJob somewhere between 1.39 and 1.44.
gem "google-cloud-storage", "1.38.0"
gem "graphiql-rails", "1.4.10", group: :development
gem "graphql", "~> 1.13.19"
gem "health-monitor-rails", "~>12.1"
gem "honeybadger"
gem "hydra-access-controls", github: "samvera/hydra-head", branch: "main"
gem "hydra-derivatives", github: "samvera/hydra-derivatives", branch: "relax_rails"
gem "hydra-head", github: "samvera/hydra-head", branch: "main"
gem "hydra-role-management"
gem "iiif_manifest", "1.1.1"
gem "iso-639"
gem "jbuilder"
gem "jquery-datatables"
gem "jquery-rails"
gem "jquery-ui-rails", "~> 6.0"
gem "json-schema"
gem "lazily"
gem "lcsort", ">= 0.9.1"
gem "leaflet-rails"
gem "lograge"
gem "lograge-sql"
gem "logstash-event"
gem "loofah"
gem "m3u8"
gem "marc"
gem "mediainfo", "~> 1.0", github: "pulibrary/mediainfo", branch: "further_sanitize_track_names"
gem "mime-types"
gem "mini_magick"
gem "modernizr-rails"
# Pin because capistrano raises an error at >= 7.2
gem "net-ssh", "~> 7.1.0"
gem "normalize-rails"
gem "oai"
gem "omniauth", "1.9.2"
gem "omniauth-cas", "2.0.0"
gem "openseadragon"
gem "pg"
gem "prawn"
gem "puma"
gem "rack"
gem "rack-cors", require: "rack/cors"
gem "rails", "~> 7.1.0"
gem "recipient_interceptor"
gem "redis", ">= 3", "< 5"
gem "redis-namespace"
gem "reform"
gem "riiif"
gem "rsolr"
gem "ruby-progressbar"
gem "ruby_tika_app", git: "https://github.com/pulibrary/ruby_tika_app", branch: "main"
gem "ruby-vips"
gem "rubyzip"
gem "shrine-google_cloud_storage"
gem "simple_form"
gem "sprockets"
gem "string_rtl"
gem "title"
gem "tus-server", "~> 2.3"
gem "valkyrie", "~> 3.0.0"
gem "valkyrie-derivatives", git: "https://github.com/samvera-labs/valkyrie-derivatives.git"
gem "valkyrie-sequel", "~> 3.0.0-beta.1"
gem "valkyrie-shrine"
gem "view_component", require: "view_component/engine"
gem "vite_rails"
gem "whenever", "~> 0.10"

# Required for deployment under ruby 3.1
gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false

source "https://gems.contribsys.com/" do
  gem "sidekiq-pro"
end

group :development do
  gem "benchmark-ips"
  gem "foreman"
  gem "listen"
  gem "ruby-prof"
  gem "solargraph"
  gem "spring"
  gem "web-console"
end

group :development, :test do
  gem "awesome_print"
  gem "bcrypt_pbkdf"
  gem "bixby", "~> 5.0"
  gem "bundler-audit", require: false
  gem "debug"
  gem "dotenv-rails"
  gem "ed25519"
  gem "factory_bot_rails"
  gem "parallel_tests"
  gem "pdf-reader", github: "yob/pdf-reader"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rails-controller-testing"
  gem "rspec-rails"
end

group :development, :staging do
  gem "rack-mini-profiler", require: ["prepend_net_http_patch"]
end

group :test do
  gem "capybara-screenshot"
  gem "database_cleaner"
  gem "database_cleaner-sequel"
  gem "formulaic"
  gem "rspec-graphql_matchers", "~> 1.3.1"
  gem "rspec_junit_formatter"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end
