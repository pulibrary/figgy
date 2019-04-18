# frozen_string_literal: true
namespace :fixity do
  desc "Run task queue worker"
  task run_worker: :environment do
    Fixity::Worker.run!
  end
end
