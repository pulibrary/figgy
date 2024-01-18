# Preservation Audits

In order to ensure resources are consistently and successfully preserved, we use our optional DLS discussion time every 4 months to ensemble kick off the preservation audit, and then the one two weeks after to review the results. Calendar events are created each year for this set of meetings, with a agenda item after the last one to review the process and potentially set up the next set of meetings.

## Run an initial audit

Audit files are saved in the capistrano shared directory to ensure they persist
between deploys, however they are not shared between machines, so all tasks for
a given audit must be run on the same machine.

A full audit takes more than a week, and needs to be regularly checked in order to resume it if it is interrupted.

The following full audit tasks can be found in `lib/tasks/preservation.rake`:
  * figgy:preservation:full_audit_restart - Use this task to run the initial full audit
  * figgy:preservation:full_audit_resume - Use this task if the full audit process is interrupted

See the tasks in that file for the location to access the reports.

## How to repair resources that failed to preserve

Look through the audit report and investigate the resources that failed to identify patterns, create tickets, and fix bugs.

Once a bug has been resolved, use the audit report as an input to re-preserve
the resources that failed the audit. Use something like the following inside the
each loop:

```
PreserveResourceJob.set(queue: :super_low).perform_later(id: resource.id.to_s,
force_preservation: true)
```

## Run a recheck report

The following recheck audit tasks can be found in `lib/tasks/preservation.rake`:
  * figgy:preservation:recheck_restart - Use this task to audit just the contents of a full audit report
  * figgy:preservation:recheck_again - Use this task to audit the contents of the most recent recheck report

Resolving failures and running a recheck report can continue as needed until all preservation issues are resolved.
