# frozen_string_literal: true
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :job_template, "bash -l -c 'export PATH=\"/usr/local/bin/:$PATH\" && :job'"
job_type :logging_rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

every :day, at: "11:00 PM", roles: [:db] do
  logging_rake "figgy:update_bib_ids", output: "/tmp/figgy_update_bib_ids.log"
  # Disabled - it wasn't working and the requests from DPUL working to reindex
  # from Figgy were crashing Figgy.
  # logging_rake "figgy:refresh:finding_aids:all", output: "/tmp/figgy_update_finding_aids.log"
end

every :monday, at: "10am", roles: [:db] do
  rake "figgy:send_collection_reports"
end

# We've disabled DAO synchronization until Pulfalight can handle this.
# every :monday, at: "7am", roles: [:production_db] do
#   rake "export:pulfa"
# end

every :day, at: "9:00 PM", roles: [:db] do
  rake "fixity:request_daily_cloud_fixity"
end

every 10.minutes, roles: [:db] do
  rake "cdl:bulk_hold_process"
end

every 1.hour, roles: [:db] do
  rake "cdl:automatic_ingest"
end

every :hour, roles: [:db] do
  rake "cdl:automatic_completion"
end

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
