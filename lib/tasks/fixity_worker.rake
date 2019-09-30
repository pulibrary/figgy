# frozen_string_literal: true
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
end
