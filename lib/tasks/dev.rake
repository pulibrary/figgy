# frozen_string_literal: true
if Rails.env.development? || Rails.env.test?
  require "factory_girl"

  namespace :dev do
    desc "Sample data for local development environment"
    task prime: "db:setup" do
      include FactoryGirl::Syntax::Methods

      # create(:user, email: "user@example.com", password: "password")
    end
  end

  namespace :server do
    desc "Start solr server for testing."
    task :test do
      shared_solr_opts = { managed: true, verbose: true, persist: false }
      shared_solr_opts[:version] = ENV['SOLR_VERSION'] if ENV['SOLR_VERSION']

      SolrWrapper.wrap(shared_solr_opts.merge(port: 8984, instance_dir: 'tmp/blacklight-core-test')) do |solr|
        solr.with_collection(name: "blacklight-core-test", dir: Rails.root.join("solr", "config").to_s) do
          puts "Solr running at http://localhost:8984/solr/blacklight-core-test/, ^C to exit"
          begin
            sleep
          rescue Interrupt
            puts "\nShutting down..."
          end
        end
      end
    end

    desc "Cleanup test servers"
    task :clean_test do
      SolrWrapper.instance(managed: true, verbose: true, port: 8984, instance_dir: 'tmp/blacklight-core-test', persist: false).remove_instance_dir!
      puts "Cleaned up test solr server."
    end

    desc "Start solr server for development."
    task :development do
      SolrWrapper.wrap(managed: true, verbose: true, port: 8983, instance_dir: 'tmp/blacklight-core', persist: false) do |solr|
        solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "config").to_s) do
          puts "Setup solr"
          puts "Solr running at http://localhost:8983/solr/blacklight-core/, ^C to exit"
          begin
            sleep
          rescue Interrupt
            puts "\nShutting down..."
          end
        end
      end
    end
  end
end
