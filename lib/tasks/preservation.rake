# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  namespace :preservation do
    desc "Reports the number of unpreserved models."
    task count_unpreserved: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      failures = PreservationStatusReporter.run_full_audit(io_directory: state_directory)
      failed_count = failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The report and the resumption timestamp have been saved to #{state_directory}"
    end

    desc "Reports the number of unpreserved models."
    task recheck_ids: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      failures = PreservationStatusReporter.run_recheck(io_directory: state_directory)
      failed_count = failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The report has been saved to #{state_directory}"
    end
  end
end
