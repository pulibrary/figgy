# frozen_string_literal: true
namespace :cdl do
  desc "Active/Expire all CDL Holds"
  task bulk_hold_process: :environment do
    CDL::BulkHoldProcessor.process!
  end
end
