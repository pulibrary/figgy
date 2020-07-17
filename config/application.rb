# frozen_string_literal: true
require_relative "boot"
require_relative "read_only_mode"
require "rails"
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
Bundler.require(*Rails.groups)
module Figgy
  class Application < Rails::Application
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
        origins "*"
        resource "/graphql", headers: :any, methods: [:post]

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
    config.active_record.sqlite3.represent_boolean_as_integer = true
    # load overrides
    config.to_prepare do
      Dir.glob(Rails.root.join("app", "**", "*_override*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
    config.action_mailer.deliver_later_queue_name = "high"
  end
end
