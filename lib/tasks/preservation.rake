# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  namespace :preservation do
    desc "Reports the number of unpreserved models."
    task count_unpreserved: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      auditor = PreservationStatusReporter.new(from_file: ENV["FROM_FILE"])
      auditor.load_state!(state_directory: state_directory)
      failed_count = auditor.cloud_audit_failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The bad_resources.txt report and the resumption timestamp have been saved to #{state_directory}"
    end
  end
end
