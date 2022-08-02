# frozen_string_literal: true
module RackBuilderConfig
  def adapter(*args)
    if ENV["TEST_ENV_NUMBER"]
      use(:parallel_solr_middleware)
    end
    super
  end
end
::Faraday::RackBuilder.send(:prepend, RackBuilderConfig)
class ParallelSolrMiddleware < Faraday::Middleware
  attr_reader :app, :parallel_key
  def initialize(app)
    @app = app
    @parallel_key = ENV["TEST_ENV_NUMBER"]
  end

  def call(env)
    return app.call(env) unless env.url.to_s.include?("solr")
    if env.method == :post
      # Override delete_by_query to filter
      if env.body.include?("delete") && env.body.include?("query")
        json_body = JSON.parse(env.body)
        json_body["delete"]["query"] = "parallel_core_ssi:#{parallel_key}"
        env.body = JSON.dump(json_body)
      end
    elsif env.method == :get
      env.url.query = add_query_param(env.url.query, "fq", parallel_key)
    end
    app.call env
  end

  def add_query_param(query, key, value)
    query = query.to_s
    query << "&" unless query.empty?
    query << "#{Faraday::Utils.escape key}=parallel_core_ssi:#{value}"
  end
end

Rails.application.config.to_prepare do
  if ENV["TEST_ENV_NUMBER"]
    Faraday::Middleware.register_middleware parallel_solr_middleware: -> { ParallelSolrMiddleware }
  end
end
