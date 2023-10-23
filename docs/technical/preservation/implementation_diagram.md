# Implementation Diagram

`FileSetPreservationObject` and `ResourcePreservationObject` are separated below for visual purposes - both in the code are `PreservationObject`. Similarly, `MetadataFileMetadata` and `BinaryFileMetadata` are both `FileMetadata`.

```mermaid
erDiagram
    Resource ||--o| ResourcePreservationObject : has_one
    FileSet ||--o| FileSetPreservationObject : has_one
    Resource {
      Valkyrie-ID id PK
      token[] optimistic_lock_token
    }
    Resource ||--o{ FileSet : has_many
    FileSet {
      Valkyrie-ID id pk
      token[] optimistic_lock_token
    }
    FileSet ||--o{ FileMetadata : has_many
    FileMetadata {
      Valkyrie-ID id PK
      checksum[] checksum
      Valkyrie-ID[] file_identifiers
    }
    ResourcePreservationObject {
      Valkyrie-ID id PK
      Valkyrie-ID preserved_object_id FK
      FileMetadata metadata_node
      string metadata_version
    }
    ResourcePreservationObject ||--|| MetadataFileMetadata : "has_one metadata_node"
    FileSetPreservationObject {
      Valkyrie-ID id PK
      Valkyrie-ID preserved_object_id FK
      FileMetadata metadata_node
      FileMetadata[] binary_nodes
      string metadata_version
    }
    FileSetPreservationObject ||--|| MetadataFileMetadata : "has_one metadata_node"
    FileSetPreservationObject ||--o{ BinaryFileMetadata : "has_many binary_nodes"
    MetadataFileMetadata {
      checksum[] checksum
      Valkyrie-ID file_identifiers
    }
    BinaryFileMetadata {
      checksum[] checksum
      Valkyrie-ID[] file_identifiers
      Valkyrie-ID preservation_copy_of_id FK
    }
    FileMetadata ||--|| BinaryFileMetadata : "has_one"
    Event {
      Valkyrie-ID id PK
      string type
      string status
      boolean current
      Valkyrie-ID resource_id FK
      string child_property
      Valkyrie-ID child_id FK
    }
    FileSetPreservationObject ||--o{ Event : "has_many (resource_id)"
    Event ||--|| BinaryFileMetadata : "references (child_id)"
```

## Preservation

Preservation is triggered when a resource is marked complete by `ChangeSetPersister::PreserveResource` and runs so long as `ChangeSet.for(resource).preserve?` returns true.

### Scanned Resource Walkthrough
Scenario: The ScannedResource is completed.

1. `ChangeSet::PreserveResource` is run, checking `ChangeSet.for(resource).preserve?`
   * Default `ChangeSet#preserve?`: https://github.com/pulibrary/figgy/blob/426da54c79bbbd08216f8edb05f034f3659ab41e/app/change_sets/change_set.rb#L108-L118
2. Enqueue `PreserveResourceJob`, which runs `Preserver#preserve!`
3. Create a `PreservationObject` for the `ScannedResource`
   * We use PreservationObject to save the cloud / preserved locations of preservation files, so that we don't add new metadata values to the objects that we are preserving, thus necessitating another preservation action.
4. Preserve metadata
   * A JSON serialization of the metadata is uploaded to GCS and its checksum stored in the `metadata_node` attached to the PreservationObject.
   * The PreservationObject's `metadata_version` field is updated with the `Resource`'s current lock token, so we can ensure that the `PreservationObject` and `Resource` are in sync.
5. Enqueue preservation of children.
   * Every time it's run the preserver will automatically enqueue preservation of any children which have never been preserved.

### FileSet Walkthrough

Scenario: The ScannedResource with one FileSet is completed.
* PreserveChildrenJob queues a PreserveResourceJob for each of the members.
* PreserveResourceJob is just a wrapper for the Preserver class.
* `preserve!` creates a `PreservationChecker::Binary` for each file metadata on the FileSet. Gives an option to force the preservation, otherwise only preserves if it hasn't been preserved before.
* After it preserves the binary nodes, it preserves the metadata, as outlined above. It doesn't have any children to preserve.


```mermaid
sequenceDiagram
  participant User
  participant Figgy as Figgy
  participant GCS as Google Cloud
  User->>Figgy: mark resource complete
  Figgy->>GCS: store the files and metadata
```

### Cloud Fixity Check

Scenario: A preserved object exists in Google Cloud
Note: Some of this process is documented in [ADR #4, Preservation Fixity](https://github.com/pulibrary/figgy/blob/main/architecture-decisions/0004-preservation-fixity.md).
* The `request_daily_cloud_fixity` task is run 9PM everyday.
  * https://github.com/pulibrary/figgy/blob/150e9def951fd0b1ea8f948069f5a0225fff4f4f/config/schedule.rb#L19
* The task runs the `CloudFixity::FixityRequestor.queue_daily_check!` method with an 10% annual ratio.
  * https://github.com/pulibrary/figgy/blob/3276f1923c80b3b26929228b7b2fecebf9a90ef8/lib/tasks/fixity_worker.rake#L13
  * The method computes the number of the resources that need to be check to satisfy the annual ratio, and publishes file information to a fixity request Google PubSub topic.
* In Google Cloud, we have a [Cloud Function](https://github.com/pulibrary/figgy/blob/150e9def951fd0b1ea8f948069f5a0225fff4f4f/cloud_fixity/index.js) that listens to the fixity request topic.
  * A compute promise is constructed that pipes the file into an md5 hash.
  * If the calculated md5 value equals the md5 value passed in the request data, then a 'success' message is published. If not, a 'failure' message is published.
  * If there is an error when streaming the file, a retry_count attribute is added to the request data and it is re-queued. After 5 attempts, a 'failure' message is published.
  * A message gets published to the fixity status topic queue.
  * Cloud Fixity Worker kicks off a UpdateFixityJob which results in an Event getting saved, and notifies Honeybadger if there's a failed fixity check.

### Local Fixity Check
Scenario: A new file is ingested.
* After ingesting, CharacterizationJob runs (creates checksums), then runs
    CreateDerivativesJob
* After derivatives are created in CreateDerivativesJob, it calls
    LocalFixityJob via perform_later.
  * Calls `run_fixity` on the file set, which delegates to the primary_file
      * Runs checksums on the file on disk and compares it to the previously
          stored checksum. If it matches, it creates a success Event.

Scenario: A FileSet exists in Figgy, it should be occasionally confirmed its
fixity is correct.
* `rake figgy:fixity:request_daily_local_fixity` is run every day. It checks a random 1/365th of the repository every day.

### Fixity status show page display
Scenario: Looking at a Scanned Resource

We display fixity summary in three places:

#### Resource Show Page

https://github.com/pulibrary/figgy/blob/c106ea719f9473e0fc3d0bfa608da0d345ab4a94/app/views/catalog/_resource_attributes_default.html.erb#L30-L39


It uses a decorator which uses a helper. The helper makes queries about failed
  and succeeded fixity checks.
  * https://github.com/pulibrary/figgy/blob/c106ea719f9473e0fc3d0bfa608da0d345ab4a94/app/decorators/valkyrie/resource_decorator.rb#L89-L99
  * https://github.com/pulibrary/figgy/blob/c106ea719f9473e0fc3d0bfa608da0d345ab4a94/app/helpers/fixity_dashboard_helper.rb#L40-L42

#### Member Resource List on Show Page (for MVW)

There's also fixity_badges, which is used in the member_resources list. Look at this next time.

We call fixity_badges from here:

https://github.com/pulibrary/figgy/blob/030a01df143cebe3c3c8a8a09d7ccb4be1170a7f/app/views/catalog/_member_resources.html.erb#L50

This displays the local fixity count, but with no status. The status helper
calls the count method.

#### File Set Show Page

https://github.com/pulibrary/figgy/blob/030a01df143cebe3c3c8a8a09d7ccb4be1170a7f/app/views/catalog/_members_file_set.html.erb

This has a column for local fixity and cloud fixity for every FileMetadata, but
only the primary file will ever have a populated success/failure.

https://github.com/pulibrary/figgy/blob/030a01df143cebe3c3c8a8a09d7ccb4be1170a7f/app/views/catalog/_file_detail.html.erb

This uses the same helpers, `format_fixity_success` and
`format_cloud_fixity_success`, but also displays the last success date for each.

### Fixity Dashboard

Note that it's slow. Takes a minute to load due to
https://github.com/pulibrary/figgy/issues/5545

The code here is very straightforward. See FixityDashboardController and
accompanying template / partials.

### Creation of Tombstones

There's a CreateTombstone before delete hook in the change set persister.

It saves some identifiers and embeds the preservation object.

The Tombstone model: https://github.com/pulibrary/figgy/blob/main/app/models/tombstone.rb

### Restore Tombstones

When a fileset has been deleted there's a "Deleted Files" section in the File
Manager. Each deleted file is listed by title with a "Reinstate" button.

There's a `child_tombstones` method on the wayfinder to power this list. Uses
the parent_id stored on the tombstone. Currently only implemented for
ScannedResources.

Uses tombstone_restore_ids to pass the value to the restore_tombstones.rb change_set_persister callback.
- The importer pulls the metadata and binary down from the cloud.
- The metadata is converted back into a FileSet object using the Valkyrie Sequel ORM converter. This restores id, created date, updated date, and internal resource.
- Currently intermediate files are not preserved/restorable.
- The PCDM use is not restored.

### Blind Importer

You have to call BlindImporter from the rails console.

- BlindImporter uses FileMetadataAdapter's query_service which navigates Google
Cloud.
- This retains the PCDM use for FileSets by keeping the preserved FileMetadata
    and pointing them to newly uploaded copies of the files.
  * Instead of using FileAppender via `files: ` in the ChangeSet, it sets the
      `created_file_sets` property to trigger characterization/derivatives.
- It recurses through resource membership and imports every member.
- FileMetadataAdapter::ConvertLocalStorageIDs converts preserved file
    identifiers to their GCS counterparts, and makes sure they all exist, and
    returns the ones that exist.
