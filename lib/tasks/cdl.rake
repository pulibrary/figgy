# frozen_string_literal: true
namespace :figgy do
  namespace :cdl do
    desc "Active/Expire all CDL Holds"
    task bulk_hold_process: :environment do
      return unless Figgy.cdl_enabled?
      CDL::BulkHoldProcessor.process!
    end

    desc "Automatically ingest everything in the CDL ingest directory"
    task automatic_ingest: :environment do
      return unless Figgy.cdl_enabled?
      CDL::AutomaticIngester.run
    end

    desc "Automatically complete processed CDL items."
    task automatic_completion: :environment do
      return unless Figgy.cdl_enabled?
      CDL::AutomaticCompleter.run
    end
  end
end
