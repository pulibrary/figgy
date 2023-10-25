# 10. Resource Auto Completion

Date: 2023-04-18

## Status

Accepted

## Context

Our users often don't have time to go back to a resource they've ingested and
check to see if it's okay after the initial ingest, and so tend to immediately
mark a resource complete at ingest time. Unfortunately this results in a lot of
churn in our preservation infrastructure - every file that gets added during
that ingest forces a re-preservation of the parent's metadata.

To prevent that, and also make sure that resources are being completed that are
useful to our patrons, we want to add a new state that will automatically mark a
resource complete when all of its files are attached and the derivatives
generated.

This auto-completion could be handled in one of two ways - either via a cron
job that runs on some regular interval or by utilizing [Sidekiq
Batches](https://github.com/sidekiq/sidekiq/wiki/Batches).

The cron job would not be as immediate, but would be easy to maintain and reason through.
The batches would allow us to track the lifecycle of the object through jobs and would
enable early-as-possible completion, but would be
unable to handle adding files post-bulk-ingest but pre-auto-complete, would
require us to avoid deleting jobs from Sidekiq (or the batches would never
succeed), would be harder to test, and would be much harder to reason through the edge cases
of.

Further, while normally we'd have to worry about race conditions in the cron
job, all of our resources have optimistic locking enabled - if two crons run into
one another, one would win appropriately and the second would error. We could then
send those errors to Honeybadger to track any problems with the auto completer.

## Decision

We will use a cron job that will automatically complete all resources that are
`complete_when_processed`, have members, and all of its file sets are processed.

## Consequences

* We'll be unable to tell from the UI when a resource will never possibly
    complete because we won't be tracking the actual jobs involved. We may have
    to add some other kind of job tracking in the future.
