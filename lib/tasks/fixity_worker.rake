# frozen_string_literal: true
namespace :fixity do
  desc "Run task queue worker"
  task run_worker: :environment do
    CloudFixity::Worker.run!
  end

  desc "Request fixity check of PERCENT resources"
  task request_random_fixity: :environment do
    logger = Logger.new(STDOUT)
    percent_of_resources = ENV["PERCENT_OF_RESOURCES"]
    abort "usage: rake fixity:request_random_fixity PERCENT_OF_RESOURCES=10" unless percent_of_resources
    CloudFixity::FixityRequestor.queue_random!(percent: percent_of_resources.to_i)
    logger.info "Queued #{percent_of_resources}% of Cloud Preserved resources for fixity checking."
  end
end
