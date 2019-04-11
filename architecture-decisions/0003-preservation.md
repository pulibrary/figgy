# 3. Preservation

Date: 2019-04-02

## Status

Accepted

## Context

We have agreed that we will preserve digital objects by saving resources in
Google Cloud Storage in a directory structure which preserves both the binaries
the resource is made up of as well as the JSON serialization of the resource
itself.

## Decisions

1. Preserving
   1. We will preserve materials in Google Cloud Coldline Storage with
      `versioning` enabled. Versions will be kept indefinitely and without
      limit. All files will go in a single bucket.
      - Staging bucket is configured with the following command:
        ```
        gsutil mb -c regional -l us-west1 -p pulibrary-figgy-storage-1 gs://figgy-staging-preservation
        echo '{"rule": [{"action": {"type": "Delete"}, "condition": {"age": 2}}]}' > lifecycle.json
        gsutil lifecycle set lifecycle.json gs://figgy-staging-preservation
        rm lifecycle.json
        gsutil bucketpolicyonly set on gs://figgy-staging-preservation
        gsutil iam ch serviceAccount:figgy-staging@pulibrary-figgy-storage-1.iam.gserviceaccount.com:objectAdmin gs://figgy-staging-preservation
        ```
      - Production bucket is configured with the following command:
        ```
        gsutil mb -c coldline -l us-west1 -p pulibrary-figgy-storage-1 gs://figgy-preservation
        gsutil bucketpolicyonly set on gs://figgy-preservation
        gsutil iam ch serviceAccount:figgy-preservation-production@pulibrary-figgy-storage-1.iam.gserviceaccount.com:objectAdmin gs://figgy-preservation
        gsutil versioning set on gs://figgy-preservation
        ```
   1. When a resource is `complete` and marked with the `cloud` preservation
      policy it will save itself and all resources contained in `member_ids` in
      a directory structure in Google Cloud Storage that looks like the
      following:
      ```
      - <resource-id>
        - data
          - <child-id>
            - <child-id>.json
            - <binary.tif>
        - <resource-id>.json
      ```
   1. Children are preserved on save if their parents are preserved.
   1. Related objects such as collections, Ephemera Terms, etc. will not be
      packaged inside the preserved object. If it's important they be preserved,
      those objects should be marked with the `cloud` preservation policy.
   1. When a FileSet is added to a resource which is already complete and marked
      with the `cloud` preservation policy, it will upload the new binary
      content to both the repository and to Google Cloud Storage.
   1. If a child is marked to be preserved, but its parent is not, it will still
      save in a nested directory structure, but will not automatically create
      backups of its parents.
   1. This behavior will be attached to the ChangeSetPersister.
1. Packaging Details
   1. When preserved a `PreservationObject` will be created in Figgy with a
      `preserved_object_id` property which points to the object it's preserving.
   1. Each `PreservationObject` will contain `FileMetadata` for the binary
      object as well as a serialized JSON file of the resource it's preserving.
      On upload to preservation, those items' checksums will be calculated and
      stored on the `PreservationObject`.
   1. JSON metadata will have the use `pcdm:PreservedMetadata` and binary
      content will have the use `pcdm:PreservationCopy`
   1. We will only keep the most recent version of any file, overwriting any
      files which match the same file name, but relying on versioning to go back
      if necessary.
   1. When a preserved resource is deleted, we will delete its directory from
      preservation storage. If we need to get it again, we will look at Google
      Cloud Storage's stored versions.
   1. If a child's hierarchy changes (it moves parents), we will move the
      content in the preservation storage to match.
   1. When a file's binary content is replaced on disk, we will upload a new
      copy of the file to preservation and calculate a new checksum.
2. Fixity Checks
   1. Technical details of fixity checking will occur in a later ADR.
   1. A random subset of the preserved copies will have their files pulled down
      from preservation storage, their checksums calculated as they're streamed,
      and then compared to the checksum of the object stored locally.
   1. In the case of a failure it will be reported to Figgy and displayed in a
      dashboard for further follow-up and repair.

## Consequences

1. Structure
   1. The resultant structure will not be in a format that is expected by
      outside vendors. However, we have a BagIt packager for those use cases,
      and this structure can be easily converted to a BagIt bag by creating
      manifests using the checksums in the metadata files.
1. "State at Time of Preservation"
   1. As we are not preserving "related" resources as part of the resource, we
      are not preserving the values of controlled vocabularies at time of
      preservation. As of now, we do not have this use case, and are more
      concerned with our material not being lost in the event of a technical
      failure.
1. Storage Format
   1. Storing items in individual files means we will be unlikely to move to
      another cloud storage with a delay on reads, like AWS Glacier.
1. Finding a child resource
   1. Storing in a nested structure means if somebody needs to find a child
      resource we need information about its parent in order to find it. We
      expect this to not be a problem - requests are often "can I get page 6 of
      X", not "can I get the file with this ID." However, if necessary we can
      iterate over the file listing in cloud storage to find it.
1. Versioning
   1. Versioning everything may mean keeping copies of things that are never
      used, and wasting space. We don't expect this to be a big problem as files
      don't move around a lot post-complete. If it is, we can re-evaluate our
      versioning strategy.
