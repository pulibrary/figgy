# 2. Sidekiq Queues

Date: 2019-02-07

## Status

Accepted

## Context

We have background jobs that are processed by Sidekiq workers on several dedicated background processing
machines.  The background jobs include a variety of different tasks from different sources:
* processing user requests (e.g., ingesting files, (re)generating derivatives)
* cleaning up after user actions (e.g., propagating state and visibility, removing files before deleting
   their parent resource)
* refreshing metadata from Voyager/PULFA
* bulk-ingesting content
* routine cleanup (cleaning out guest users)
* fixity checking

## Decision

We will have three queues for processing background jobs:
1. `default` for processing user-initiated requests needed for ingesting and displaying objects
2. `low` for bulk processing, validation, cleanup, etc.
3. `super_low` for fixity checking and other long-term preservation actions

## Consequences

* Fixity checking from user-initiated ingest will be lower priority than bulk ingest or processing, and may
   be significantly delayed when there are large volumes of materials being ingested.
