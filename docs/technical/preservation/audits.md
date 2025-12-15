# Preservation Audits

In order to ensure resources are consistently and successfully preserved, we use our optional DLS discussion time every 4 months to ensemble kick off the preservation audit, and then the one two weeks after to review the results. Calendar events are created each year for this set of meetings, with a agenda item after the last one to review the process and potentially set up the next set of meetings.

## Run a recheck report

Start another audit using the `rerun` method and passing in the audit you want to check failures from. Get the audit id from the figgy UI.

ssh to the box, open a tmux session, and go into the rails console

```
id = get_from_figgy_ui
audit = PreservationAudit.find(id)
PreservationAuditRunner.rerun
```

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

## Run an initial audit

ssh to the box, open a tmux session, and go into the rails console

do `PreservationAuditRunner.run; nil`

You will see the batch at /sidekiq/batches. Jobs queue to super_low.
You will see the audit at /preservation_audits.

We will get an email notification via our libanswers queue when the batch succeeds with all check correct, succeeds with preservation check failures, completes but with job failures (that will be rerun, since they are sidekiq jobs), or sends any job to the dead queue.
