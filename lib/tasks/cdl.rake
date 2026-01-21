namespace :figgy do
  namespace :cdl do
    desc "Active/Expire all CDL Holds"
    task bulk_hold_process: :environment do
      if Figgy.cdl_enabled?
        CDL::BulkHoldProcessor.process!
      end
    end

    desc "Automatically ingest everything in the CDL ingest directory"
    task automatic_ingest: :environment do
      if Figgy.cdl_enabled?
        CDL::AutomaticIngester.run
      end
    end

    desc "Automatically complete processed CDL items."
    task automatic_completion: :environment do
      if Figgy.cdl_enabled?
        CDL::AutomaticCompleter.run
      end
    end
  end
end
