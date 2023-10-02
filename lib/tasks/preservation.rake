# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  namespace :preservation do
    desc "Reports the number of unpreserved models."
    task count_unpreserved: :environment do
      auditor = PreservationStatusReporter.new
      total = auditor.audited_resource_count
      progress_bar = ProgressBar.create format: "%a %e %P% Querying: %c from %C", total: total
      failed_count = auditor.cloud_audit_failures { progress_bar.increment }.map(&:id).eager.count
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
    end
  end
end
