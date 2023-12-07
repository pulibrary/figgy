# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  namespace :preservation do
    desc "Reports the preservation problems found in all resources, resumable."
    task count_unpreserved: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      auditor = PreservationStatusReporter.new
      auditor.load_state!(state_directory: state_directory)
      failed_count = auditor.cloud_audit_failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The #{auditor.output_filename} report and the resumption timestamp have been saved to #{state_directory}"
    end

    desc "Re-checks preservation problems identified in a previously-run report."
    task recheck: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      auditor = PreservationStatusIdChecker.new
      auditor.load_state!(state_directory: state_directory)
      failed_count = auditor.cloud_audit_failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The #{auditor.output_filename} report and the resumption timestamp have been saved to #{state_directory}"
    end
  end
end
