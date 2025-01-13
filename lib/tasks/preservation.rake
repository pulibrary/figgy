# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  namespace :preservation do
    desc "Reports the number of unpreserved models, first rotating previous resumption and output files"
    task full_audit_restart: :environment do
      root_dir = Pathname.new("/opt/figgy/current")
      if Rails.env.development? || Rails.env.test?
        root_dir = Rails.root
      end
      state_directory = root_dir.join("tmp", "rake_preservation_audit")
      PreservationStatusReporter.rotate_file(state_directory.join(PreservationStatusReporter::FULL_AUDIT_OUTPUT_FILE))
      PreservationStatusReporter.rotate_file(state_directory.join(PreservationStatusReporter::RESUME_TIMESTAMP_FILE))

      reporter = PreservationStatusReporter.full_audit_reporter(io_directory: state_directory)
      failures = reporter.cloud_audit_failures
      failed_count = failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The #{PreservationStatusReporter::FULL_AUDIT_OUTPUT_FILE} report and the resumption timestamp have been saved to #{state_directory}"
    end

    desc "Reports the number of unpreserved models, resuming from last run"
    task full_audit_resume: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      reporter = PreservationStatusReporter.full_audit_reporter(io_directory: state_directory)
      failures = reporter.cloud_audit_failures
      failed_count = failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The #{PreservationStatusReporter::FULL_AUDIT_OUTPUT_FILE} report and the resumption timestamp have been saved to #{state_directory}"
    end

    desc "Reports the number of unpreserved models, deleting previous recheck output file to ensure it reads from a full audit output file"
    task recheck_restart: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      PreservationStatusReporter.rotate_file(state_directory.join(PreservationStatusReporter::RECHECK_OUTPUT_FILE))

      reporter = PreservationStatusReporter.recheck_reporter(io_directory: state_directory)
      failures = reporter.cloud_audit_failures
      failed_count = failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The #{PreservationStatusReporter::RECHECK_OUTPUT_FILE} report has been saved to #{state_directory}"
    end

    desc "Reports the number of unpreserved models, using a previous recheck output file if found"
    task recheck_again: :environment do
      state_directory = Rails.root.join("tmp", "rake_preservation_audit")
      reporter = PreservationStatusReporter.recheck_reporter(io_directory: state_directory)
      failures = reporter.cloud_audit_failures
      failed_count = failures.to_a.size
      puts "Number of Resources Needing Re-Preserved: #{failed_count}"
      puts "The #{PreservationStatusReporter::RECHECK_OUTPUT_FILE} report has been saved to #{state_directory}"
    end
  end
end
