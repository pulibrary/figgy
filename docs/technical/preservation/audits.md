# Preservation Audits

In order to ensure resources are consistently and successfully preserved, we use our optional DLS discussion time every 4 months to ensemble kick off the preservation audit, and then the one two weeks after to review the results. Calendar events are created each year for this set of meetings, with a agenda item after the last one to review the process and potentially set up the next set of meetings.

## Run an initial audit - new way

ssh to a worker box, open a tmux session, and go into the rails console

do `PreservationAuditRunner.run; nil`

You will see the batch at /sidekiq/batches. Jobs queue to super_low.
You will see the audit at /preservation_audits.

We will get an email notification via our libanswers queue when the batch succeeds with all check correct, succeeds with preservation check failures, completes but with job failures (which will be rerun, since they are sidekiq jobs), or sends any job to the dead queue.

## Run an initial audit - old way

Audit files are saved in the capistrano shared directory to ensure they persist
between deploys, however they are not shared between machines, so all tasks for
a given audit must be run on the same machine.

A full audit takes more than a week, and needs to be regularly checked in order to resume it if it is interrupted.

The following full audit tasks can be found in `lib/tasks/preservation.rake`:
  * figgy:preservation:full_audit_restart - Use this task to run the initial full audit
  * figgy:preservation:full_audit_resume - Use this task if the full audit process is interrupted

In 10 minutes or so you will see a progress bar. Check on it every once in a while; it will take maybe a week to generate the full report. See the tasks in that file for the location to access the reports.

## Investigate failures

Look through the audit report and investigate the resources that failed to identify patterns, create tickets, and fix bugs.

Here are some code examples that may be useful for investigation

```
# count resources with no preservation object at all
qs = ChangeSetPersister.default.query_service
File.foreach(Rails.root.join("tmp", "rake_preservation_audit", "bad_resources.txt")).count do |line|
  resource = qs.find_by(id: line.chomp)
  preservation_object = Wayfinder.for(resource).preservation_object
  preservation_object.nil?
end
```

```
# count resources for which preservation object has no metadata node
File.foreach(Rails.root.join("tmp", "rake_preservation_audit", "bad_resources.txt")).count do |line|
  resource = qs.find_by(id: line.chomp)
  preservation_object = Wayfinder.for(resource).preservation_object
  next unless preservation_object
  preservation_object.metadata_node.nil?
end
```

You can run the above also with `preservation_object.binary_nodes.empty?` to find resources where preservation has no binary nodes.

```
# count resources for which metadata isn't properly preserved
skip_metadata_checksum = false
File.foreach(Rails.root.join("tmp", "rake_preservation_audit", "bad_resources.txt")).count do |line|
  resource = qs.find_by(id: line.chomp)
  preservation_object = Wayfinder.for(resource).preservation_object
  next unless preservation_object
  # pull first checker because there's always only one; it's just wrapped in an array for consistency with the binary checkers
  md_checker = Preserver::PreservationChecker.metadata_for(resource: resource, preservation_object: preservation_object, skip_checksum: skip_metadata_checksum).first
  !md_checker.preserved?
end
```

If count above is > 0, you can run again using `!checker.recorded_versions_match?` and `!checker.preservation_ids_match?` to see which part of preservation is wrong

```
# count resources for which at least one binary isn't properly preserved
File.foreach(Rails.root.join("tmp", "rake_preservation_audit", "sample.txt")).count do |line|
  resource = qs.find_by(id: line.chomp)
  preservation_object = Wayfinder.for(resource).preservation_object
  next unless preservation_object
  bin_checkers = Preserver::PreservationChecker.metadata_for(resource: resource, preservation_object: preservation_object)
  bin_checkers.any?{ |checker| !checker.preserved? }
end
```

If count above is > 0, you can run again using `!checker.recorded_checksums_match?` and `!checker.preservation_ids_match?` to see which part of preservation is wrong

This is just some examples of things we've done before. You may need to investigate in additional ways.

## Repair resources that failed to preserve

Once a bug has been resolved, use the audit report as an input to re-preserve
the resources that failed the audit. Use something like the following:

```
File.readlines(Rails.root.join("tmp", "rake_preservation_audit", "bad_resources.txt"), chomp: true).each { |id| PreserveResourceJob.set(queue: :super_low).perform_later(id: id.to_s, force_preservation: true) }
```

## Run a recheck report - new way

Start another audit using the `rerun` method and passing in the audit you want to check failures from. Get the audit id from the figgy UI.

ssh to a worker box, open a tmux session, and go into the rails console

```
id = get_from_figgy_ui
audit = PreservationAudit.find(id)
PreservationAuditRunner.rerun
```

## Run a recheck report - old way

The following recheck audit tasks can be found in `lib/tasks/preservation.rake`:
  * figgy:preservation:recheck_restart - Use this task to audit just the contents of a full audit report
  * figgy:preservation:recheck_again - Use this task to audit the contents of the most recent recheck report

Resolving failures and running a recheck report can continue as needed until all preservation issues are resolved.
