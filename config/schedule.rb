# frozen_string_literal: true
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :job_template, "bash -l -c 'export PATH=\"/usr/local/bin/:$PATH\" && :job'"
job_type :logging_rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

every :monday, at: "10am", roles: [:db] do
  rake "figgy:send_collection_reports"
end

# We've disabled DAO synchronization until Pulfalight can handle this.
# every :monday, at: "7am", roles: [:production_db] do
#   rake "export:pulfa"
# end

every :day, at: "9:00 PM", roles: [:db] do
  rake "figgy:fixity:request_daily_cloud_fixity"
end

every :day, at: "10:00 PM", roles: [:db] do
  rake "figgy:fixity:request_daily_local_fixity "
end

every :day, at: "11:00 PM", roles: [:db] do
  rake "figgy:clean:expired_local_files"
end

every 10.minutes, roles: [:db] do
  rake "figgy:cdl:bulk_hold_process"
end

every 1.hour, roles: [:db] do
  rake "figgy:cdl:automatic_ingest"
end

every :hour, roles: [:db] do
  rake "figgy:cdl:automatic_completion"
end

every 30.minutes, roles: [:db] do
  rake "figgy:auto_complete:run"
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
