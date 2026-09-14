# 15. Pulmap Indexing

Date: 2026-09-14

## Status

Accepted

## Context

We want to simplify the process used to index documents from Figgy into Pulmap.

## Decisions

Updating and deleting Pulmap Solr documents is now done entirely in Figgy.
Previously, GeoBlacklight documents were generated for each geo resource and
then sent to Pulmap for processing on it's own Sidekiq queue using a RabbitMQ
message. Now, a geoblacklight document is created for a geo resource and then
passed to a PulmapIndex job and run in on the low Figgy Sidekiq queue. Pulmap
no longer handles any indexing tasks.

## Consequences

- Users may notice slower updates in Pulmap if there are a many jobs queued
ahead in queues with high priority.
- The process for bulk re-indexing remains the same. Running:
```
GeoResourceReindexer.reindex_geoblacklight
```
