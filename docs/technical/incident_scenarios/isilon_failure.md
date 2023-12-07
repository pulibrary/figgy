# Isilon Failure

## Scenario

The Isilon is unrecoverable. We need to get back up as soon as possible, but eventually get it back on to Princeton-local storage. This is a restore-from-backup scenario.

## Background Information

Figgy's Isilon storage is backed up weekly to the "diglibdata2-hydra" S3 bucket in "hydra-binaries-figgy_production"

## Strategy

1. Put Figgy into read-only mode - this will bring it back up for patrons.
1. Write a Valkyrie Storage Adapter which reads/writes `disk://` File Identifiers, but goes to the S3 backup bucket.
1. Find a new place to put GIS thumbnails and Audio derivatives. Replace the derivatives and stream_derivatives StorageAdapter with the new place.
1. Take it out of read only mode - this will bring it back up for staff.
1. Regenerate the Audio derivatives and GIS thumbnails.
1. Find all FileSets created in the last two weeks and see if their file identifiers resolve. If not, record them - these are lost files (unless in Preservation).
1. Sync everything on the S3 backup to new local storage.
1. Write a migration Storage Adapter which, when the new local storage location isn't found, checks the S3 backup, and if it's found there copies it to the new local storage. This will prevent us from having to shut down Figgy writes during the sync to new storage.
1. Use the migration storage adapter.

## Implications

We'll be able to recover as fast as we can write and test the adapter.

We'll lose binary data for everything ingested and not-completed in the last week. However, we'll be able to find everything created in the last two weeks and see if their file identifiers exist in storage to see what we lost.

Between the event and Figgy going into read-only mode, things may have been written to local disks that would be lost.
