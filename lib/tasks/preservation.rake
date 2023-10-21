# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  namespace :preservation do
    desc "Reports the number of unpreserved models."
    task count_unpreserved: :environment do
      auditor = PreservationStatusReporter.new
      auditor.load_state!(state_directory: Rails.root.join("tmp", "rake_preservation_audit"))
      failed_count = auditor.cloud_audit_failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
    end
  end
end
