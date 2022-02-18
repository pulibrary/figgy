# frozen_string_literal: true

namespace :figgy do
  namespace :fixity do
    desc "Run task queue worker"
    task run_worker: :environment do
      CloudFixity::Worker.run!
    end

    # This task only outputs to logs and isn't expected to be run manually. It's
    # designed to be run by Whenever/Cron.
    desc "Queues daily fixity"
    task request_daily_cloud_fixity: :environment do
      CloudFixity::FixityRequestor.queue_daily_check!(annual_percent: 10)
    end

    desc "Queues single resource fixity check"
    task request_cloud_fixity: :environment do
      id = ENV["ID"]
      abort "usage: rake fixity:request_cloud_fixity ID=resourceid" unless id
      Rails.logger = Logger.new(STDOUT)
      CloudFixity::FixityRequestor.queue_resource_check!(id: id)
    end
  end
end
