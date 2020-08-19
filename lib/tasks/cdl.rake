# frozen_string_literal: true
namespace :cdl do
  desc "Active/Expire all CDL Holds"
  task bulk_hold_process: :environment do
    CDL::BulkHoldProcessor.process!
  end

  desc "Automatically ingest everything in the CDL ingest directory"
  task automatic_ingest: :environment do
    CDL::AutomaticIngester.run
  end

  desc "Automatically complete processed CDL items."
  task automatic_completion: :environment do
    CDL::AutomaticCompleter.run
  end
end
