# frozen_string_literal: true

# config valid only for current version of Capistrano
# lock '3.4.0'

set :application, "figgy"
set :repo_url, "https://github.com/pulibrary/figgy.git"

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'
set :deploy_to, "/opt/figgy"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', 'config/blacklight.yml', 'config/fedora.yml', 'config/config.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push("log", "tmp/derivatives", "tmp/uploads", "vendor/bundle", "staged_files")

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5
set :passenger_restart_with_touch, true

# this will keep deploys from hubot-deploy working as expected
def set_branch
  branch = ENV["BRANCH"] || "main"
  return branch unless branch == "master"
  "main"
end
set :branch, set_branch

desc "Write the current version to public/version.txt"
task :write_version do
  on roles(:app), in: :sequence do
    within repo_path do
      execute :echo, "figgy `git describe --all --always --long --abbrev=40 HEAD` `date +\"%F %T %Z\"` > #{release_path}/public/version.txt"
    end
  end
end
namespace :sidekiq do
  task :quiet do
    # Horrible hack to get PID without having to use terrible PID files
    on roles(:worker) do
      puts capture("kill -USR1 $(sudo initctl status figgy-workers | grep /running | awk '{print $NF}') || :")
    end
  end
  task :restart do
    on roles(:worker) do
      execute :sudo, :service, "figgy-workers", :restart
    end
  end
end
namespace :pubsub do
  task :restart do
    on roles(:worker) do
      execute :sudo, :service, "figgy-pubsub-worker", :restart
    end
  end
end
after "deploy:starting", "sidekiq:quiet"
after "deploy:reverted", "sidekiq:restart"
after "deploy:published", "sidekiq:restart"
after "deploy:published", "write_version"
after "sidekiq:restart", "pubsub:restart"
before "deploy:assets:precompile", "deploy:yarn_install"
before "deploy:assets:precompile", "deploy:whenever"

namespace :deploy do
  desc "Run rake yarn install"
  task :yarn_install do
    on roles(:web) do
      within release_path do
        execute("cd #{release_path} && yarn install")
      end
    end
  end

  desc "Generate the crontab tasks using Whenever"
  task :whenever do
    on roles(:db) do |host|
      within release_path do
        execute("cd #{release_path} && bundle exec whenever --update-crontab #{fetch :application} --set environment=#{fetch :rails_env, fetch(:stage, 'production')} --user=deploy --roles=#{host.roles_array.join(",")}")
      end
    end
  end

  desc "Deploy Google Cloud Function"
  task :google_cloud_function do
    on roles(:db) do
      run_locally do
        execute "cd cloud_fixity && gcloud beta functions deploy checkFixity#{fetch(:stage, 'production')} --runtime nodejs14 --set-env-vars BUCKET=#{fetch(:google_fixity_bucket)},FIXITY_STATUS_TOPIC=#{fetch(:google_fixity_status_topic)},FIXITY_REQUEST_TOPIC=#{fetch(:google_fixity_request_topic)} --trigger-topic #{fetch(:google_fixity_request_topic)} --service-account #{fetch(:google_service_account)} --entry-point checkFixity --max-instances 100"
      end
    end
  end

  namespace :geoblacklight do
    desc "Reindex Geospatial Resources (for synchronized GeoBlacklight installations)"
    task :reindex do
      execute :rake, "geoblacklight:reindex"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        execute :rake, 'cache:clear'
      end
    end
  end
end

namespace :rabbitmq do
  desc "Opens RabbitMQ Console"
  task :console do
    primary_app = primary(:app)
    port = rand(9000..9999)
    puts "Opening RabbitMQ Console on port #{port}"
    puts "Press Ctrl+C to end Console connection"
    Net::SSH.start(primary_app.hostname, primary_app.user) do |session|
      session.forward.local(port, "localhost", 15_672)
      `open http://localhost:#{port}`
      session.loop(0.1) { true }
    end
  end
end

namespace :solr do
  desc "Opens Solr Console"
  task :console do
    primary_app = primary(:app)
    solr_host = fetch(:stage, "production").to_s == "production" ? "lib-solr1" : "figgy-staging1"
    port = rand(9000..9999)
    puts "Opening Solr Console on port #{port}"
    Net::SSH.start(solr_host, primary_app.user) do |session|
      session.forward.local(port, "localhost", 8983)
      puts "Press Ctrl+C to end Console connection"
      `open http://localhost:#{port}`
      session.loop(0.1) { true }
    end
  end
end
