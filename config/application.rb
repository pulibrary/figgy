# frozen_string_literal: true
require_relative "boot"
require_relative "read_only_mode"
require "rails"
require "dotenv/rails-now"
if ["development", "test"].include? ENV["RAILS_ENV"]
  Dotenv::Railtie.load
end
require_relative "lando_env"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "active_storage/engine"
require "shrine/storage/s3"
require "shrine/storage/google_cloud_storage"
Bundler.require(*Rails.groups)
module Figgy
  class Application < Rails::Application
    config.load_defaults "6.0"
    config.action_controller.forgery_protection_origin_check = false
    config.action_dispatch.cookies_same_site_protection = :none
    config.assets.quiet = true
    config.generators do |generate|
      generate.helper false
      generate.javascripts false
      generate.request_specs false
      generate.routing_specs false
      generate.stylesheets false
      generate.test_framework :rspec
      generate.view_specs false
    end
    config.action_controller.action_on_unpermitted_parameters = :raise
    config.active_job.queue_adapter = :sidekiq
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "http://localhost:3000", /.*\.princeton\.edu$/
        resource "/graphql", headers: :any, methods: [:post], credentials: true

        # The browse everything front-end is a react app which can be run separately
        #   from the rails server in development on a different port.
        #   Permit the front-end to access the browse everything controllers.
        if Rails.env.development?
          resource "/browse/*", headers: :any, methods: [:options, :get, :post, :patch]
        end
      end
    end
    config.autoload_paths += Dir[Rails.root.join("app", "resources", "*")]
    config.autoload_paths += Dir[Rails.root.join("app", "resources", "numismatics", "*")]
    config.active_record.schema_format = :sql

    # Redirect to CAS logout after signing out of Figgy
    config.x.after_sign_out_url = "https://fed.princeton.edu/cas/logout"
    # load overrides
    config.to_prepare do
      Dir.glob(Rails.root.join("app", "**", "*_override*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
    config.action_mailer.deliver_later_queue_name = "high"

    config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, Hash, HashWithIndifferentAccess]
    # This got set on Rails 5.2 to be true, but breaks BrowseEverything. When we
    # remove BrowseEverything, remove this.
    config.action_controller.default_protect_from_forgery = false
  end
end
