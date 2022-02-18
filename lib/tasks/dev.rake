# frozen_string_literal: true

if Rails.env.development? || Rails.env.test?
  require "factory_bot"

  namespace :servers do
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

  namespace :figgy do
    desc "Promote last created user to admin"
    task set_admin_user: :environment do
      u = User.last
      puts "Making #{u} an admin"
      u.roles << Role.find_or_create_by(name: "admin")
      u.save
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
end
