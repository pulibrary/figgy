# Preservation Audits

In order to ensure resources are consistently and successfully preserved, we use our optional DLS discussion time every 4 months to ensemble kick off the preservation audit, and then the one two weeks after to review the results. Calendar events are created each year for this set of meetings, with a agenda item after the last one to review the process and potentially set up the next set of meetings.

## Run an initial audit - new way

ssh to a worker box and go into the rails console

do `PreservationAuditRunner.run; nil`

You will see the batch at /sidekiq/batches. Jobs queue to super_low.
You will see the audit at /preservation_audits.
Sidekiq will show the loader jobs running and the checker jobs enqueuing.

We will get an email notification via our libanswers queue when the batch succeeds with all check correct, succeeds with preservation check failures, completes but with job failures (which will be rerun, since they are sidekiq jobs), or sends any job to the dead queue.

## Investigate failures

Analyze the audit report and investigate the failures to identify patterns, create tickets, and fix bugs.

### Create a CSV

Here is code for generating a csv report from the failures. Use tmux; this can take a long time.

```ruby
audit = PreservationAudit.find(audit_id)
qs = ChangeSetPersister.default.query_service
failures = audit.preservation_check_failures
rows = failures.map { |failure| failure.details_hash }
path = Rails.root.join("tmp", "failure-report.csv")
CSV.open(path, "w") do |csv|
  csv << rows.first.keys
  rows.each do |row|
    csv << row.values
  end
end
```

### Ad hoc investigation

Here are code samples for direct investigations. Use tmux.
```ruby
# grab all the preservation objects
audit = PreservationAudit.find(audit_id)
qs = ChangeSetPersister.default.query_service
resources_missing_po = []
pos = audit.preservation_check_failures.map do |failure|
  po = qs.custom_queries.find_by_property(model: PreservationObject, property: :preserved_object_id, value: Valkyrie::ID.new(failure.resource_id))
  resources_missing_po << failure.resource_id if po.empty?
  po.first
end.compact
```
After this, any resource without a PO will have its id in that `resources_missing_po` array, and everything else will have a preservation object in the `pos` list.

Turns out some of the things in `resources_missing_po` just don't have a resource at all, you can do something like this to split it out if you want

```ruby
no_po = resources_missing_po.map do |id|
  qs.find_by(id: id)
rescue Valkyrie::Persistence::ObjectNotFoundError
  resources_missing << id
  nil
end.compact
```

```ruby
# count resources for which preservation object has no metadata node
pos.count do |preservation_object|
  preservation_object.metadata_node.nil?
end
```

```ruby
# count resources for which preservation object has no binary node
pos.count do |preservation_object|
  preservation_object.binary_nodes.empty?
end
```

```ruby
# count resources for which metadata isn't properly preserved
pos.count do |preservation_object|
  resource = qs.find_by(id: preservation_object.preserved_object_id)
  # pull first checker because there's always only one; it's just wrapped in an array for consistency with the binary checkers
  md_checker = Preserver::PreservationChecker.metadata_for(resource: resource, preservation_object: preservation_object).first
  !md_checker.preserved?
end
```

If count above is > 0, you can run again using `!md_checker.recorded_versions_match?` and `!md_checker.preservation_ids_match?` to see which part of preservation is wrong

```ruby
# count resources for which at least one binary isn't properly preserved
pos.count do |preservation_object|
  resource = qs.find_by(id: preservation_object.preserved_object_id)
  bin_checkers = Preserver::PreservationChecker.binaries_for(resource: resource, preservation_object: preservation_object)
  bin_checkers.any?{ |checker| !checker.preserved? }
end
```

If count above is > 0, you can run again using `!checker.recorded_checksums_match?` and `!checker.preservation_ids_match?` to see which part of preservation is wrong

This is just some examples of things we've done before. You may need to investigate in additional ways.

## Repair resources that failed to preserve

Once bugs have been resolved or analysis is otherwise done, re-preserve
the resources that failed the audit.

```ruby
audit.preservation_check_failures.each do |failure|
  PreserveResourceJob.set(queue: :super_low).perform_later(id: failure.resource_id.to_s, force_preservation: true)
end
```

## Run a recheck report - new way

Start another audit using the `rerun` method and passing in the audit you want to check failures from. Get the audit id from the figgy UI.

ssh to a worker box, open a tmux session, and go into the rails console

```ruby
id = get_from_figgy_ui
audit = PreservationAudit.find(id)
PreservationAuditRunner.rerun
```
