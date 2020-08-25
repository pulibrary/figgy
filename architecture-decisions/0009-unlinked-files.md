# 8. Unlinked Files

Date: 2020-08-25 / Archaeological

## Status

Accepted

## Context

When an ingest fails in the middle of a transaction which is adding files, the
FileSets will not get persisted. However, the files will have already been
copied to the repository via `FileAppender`. This results in files in the
repository which have no corresponding database record.

Fixing this will require development of a transactional disk StorageAdapter
which moves files at the end of a metadata transaction.

## Decisions

1. We don't have time to implement a transactional disk StorageAdapter at this
   time.
2. Accept this situation, document it here, and know we can free up space in the
   future by looking for unlinked files and deleting them.

## Consequences

1. Extra disk space will be used for files which aren't accessible. If we need
   space in the future we can find and delete them.
2. If we migrate disk storage to the cloud, we would end up paying for these
   files, and should implement transactional storage. This might also have
   implications for our migration strategy - rather than a straight RSync we may
   want to migrate database-first.
