# 6. Preservation DeletionMarkers

Updated: 2023-01-9

## Changes

Tombstone models were replaced with DeletionMarker models.

Date: 2019-09-05

## Status

Accepted

## Context

After an item is deleted from the database all traces of it are gone, but if
it's been preserved then it's possible to restore it. However, finding the
particular ID of the item to restore is difficult if all that's known are pieces
of its metadata (title, source metadata ID, etc.)

We will remedy this by storing a "deletion marker" of deleted items as a small record
of what was deleted.

## Decisions

1. When a preserved item is deleted it will create a "deletion marker" containing the following
   metadata:
   1. ID of deleted resource
   1. Title of deleted resource
   1. Original Filename of deleted resource (if a FileSet)
   1. Embedded PreservationObject that existed at time of deletion
   1. ID of Parent at time of deletion.
2. These deletion markers will be displayed in the Figgy UI and used as a way to
   discover material that can be recovered.

## Consequences

1. The database will likely have many deletion markers. If it turns out to be too many
   to reliably sift through, we may have to change our strategy.
