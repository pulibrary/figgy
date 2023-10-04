# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  namespace :preservation do
    desc "Reports the number of unpreserved models."
    task count_unpreserved: :environment do
      auditor = PreservationStatusReporter.new
      failed_count = auditor.cloud_audit_failures.map(&:id).to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
    end
  end
end
