# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  namespace :preservation do
    desc "Reports the number of unpreserved models."
    task count_unpreserved: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      csv_path = ENV["CSV_PATH"]
      auditor = PreservationStatusReporter.new(csv_path: csv_path)
      auditor.load_state!(state_directory: state_directory)
      failed_count = auditor.cloud_audit_failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The bad_resources.txt report and the resumption timestamp have been saved to #{state_directory}"
    end
  end
end
