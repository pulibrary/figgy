# frozen_string_literal: true
source "https://rubygems.org"

gem "autoprefixer-rails"
gem "blacklight"
gem "devise-guests", git: "https://github.com/cbeer/devise-guests.git"
gem "flutie"
gem "honeybadger"
gem "jquery-rails"
gem "pg"
gem "puma"
gem "rails", "~> 5.1"
gem "recipient_interceptor"
gem "sass-rails", "~> 5.0"
gem "simple_form"
gem "sprockets", ">= 3.0.0"
gem "title"
gem "uglifier"
gem "valkyrie", git: "https://github.com/samvera-labs/valkyrie.git", branch: "safe_access_controls_indexer"

group :development do
  gem "listen"
  gem "spring"
  gem "spring-commands-rspec"
  gem "web-console"
end

group :development, :test do
  gem "awesome_print"
  gem "bixby"
  gem "bullet"
  gem "bundler-audit", ">= 0.5.0", require: false
  gem "dotenv-rails"
  gem "factory_girl_rails"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails", "~> 3.5"
end

group :development, :staging do
  gem "rack-mini-profiler", require: false
end

group :test do
  gem "database_cleaner"
  gem "formulaic"
  gem "poltergeist"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end

group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

gem 'rsolr', '>= 1.0'

gem 'devise'
