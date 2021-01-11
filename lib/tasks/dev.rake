# frozen_string_literal: true
if Rails.env.development? || Rails.env.test?
  require "factory_bot"

  namespace :figgy do
    namespace :server do
      desc "Start solr and postgres servers using lando."
      task :start do
        system("lando start")
        system("rake db:create")
        system("rake db:migrate")
        system("rake db:migrate RAILS_ENV=test")
      end

      desc "Stop lando solr and postgres servers."
      task :stop do
        system("lando stop")
      end
    end

    desc "Start solr server for testing."
    task :test do
      shared_solr_opts = { managed: true, verbose: true, persist: false, download_dir: "tmp" }
      shared_solr_opts[:version] = ENV["SOLR_VERSION"] if ENV["SOLR_VERSION"]

      SolrWrapper.wrap(shared_solr_opts.merge(port: 8984, instance_dir: "tmp/figgy-core-test")) do |solr|
        solr.with_collection(name: "figgy-core-test", dir: Rails.root.join("solr", "config").to_s) do
          puts "Solr running at http://localhost:8984/solr/figgy-core-test/, ^C to exit"
          begin
            sleep
          rescue Interrupt
            puts "\nShutting down..."
          end
        end
      end
    end

    desc "Start solr server for development."
    task :development do
      SolrWrapper.wrap(managed: true, verbose: true, port: 8983, instance_dir: "tmp/figgy-core-dev", persist: false, download_dir: "tmp") do |solr|
        solr.with_collection(name: "figgy-core-dev", dir: Rails.root.join("solr", "config").to_s) do
          puts "Setup solr"
          puts "Solr running at http://localhost:8983/solr/figgy-core-dev/, ^C to exit"
          begin
            if ENV["ENABLE_RAILS"]
              # If HOST specified, bind to that IP with -b
              server_options = " -b #{ENV['HOST']}" if ENV["HOST"]
              IO.popen("rails server#{server_options}") do |io|
                io.each do |line|
                  puts line
                end
              end
            else
              sleep
            end
          rescue Interrupt
            puts "\nShutting down..."
          end
        end
      end
    end

    desc "Promote last created user to admin"
    task set_admin_user: :environment do
      u = User.last
      puts "Making #{u} an admin"
      u.roles << Role.find_or_create_by(name: "admin")
      u.save
    end
  end

  namespace :clean do
    namespace :test do
      desc "Cleanup test servers"
      task :solr do
        SolrWrapper.instance(managed: true, verbose: true, port: 8984, instance_dir: "tmp/figgy-core-test", persist: false).remove_instance_dir!
        puts "Cleaned up test solr server."
      end
    end

    namespace :development do
      desc "Delete all development metadata, index, and original/derivative data"
      task all: :environment do
        seeder = DataSeeder.new
        seeder.wipe_metadata!
        seeder.wipe_files!
      end
    end
  end
end
