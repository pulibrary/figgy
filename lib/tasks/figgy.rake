# frozen_string_literal: true
namespace :figgy do
  namespace :fixity do
    desc "runs recursive fixity check job"
    task run: :environment do
      CheckFixityRecursiveJob.set(queue: :super_low).perform_later
    end
  end
  desc "updates the remote metadata from Voyager"
  task update_bib_ids: :environment do
    if defined?(Rails) && (Rails.env == "development")
      Rails.logger = Logger.new(STDOUT)
    end
    VoyagerUpdater::EventStream.new("https://bibdata.princeton.edu/events.json").process!
  end
end
