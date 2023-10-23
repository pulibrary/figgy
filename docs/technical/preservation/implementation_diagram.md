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

### Scanned resource walkthrough
Scenario: The ScannedResource is completed.
* the ChangeSetPersister::PreserveResource is run as an after_save_commit callback.
  * calls `preserve?` on the change set.
* in the change set,
  * It has to be persisted
  * If there's a parent, return the `preserve?` check from the parent
  * If state is complete, or it doesn't respond to `state`, then preserve
  * https://github.com/pulibrary/figgy/blob/d32622f0585375a3d3cb475a8193f6b345681838/app/change_sets/change_set.rb#L102-L112
* assuming preserve? true
  * Run PreserveResourceJob as `perform_later` (wrapper for Preserver class)
* Preserver
  * `for` factory checks `change_set.preserve?` (again) so it doesn't do
    anything if that's false.
    * https://github.com/pulibrary/figgy/blob/d32622f0585375a3d3cb475a8193f6b345681838/app/services/preserver.rb#L6
  * `preserve!` will not do anything with binaries at this time since they are not attached to a scanned resource. The first time preserved, it will preserve both the metadata and members. Subsequent times preserved, it will only preserve metadata.
  * Uploads the serialized json metadata to Google Cloud (via Valkyrie::Shrine gem)
    * If the resource has changed its parent then it will re-preserve its
      children and clean up the old metadata file. In our scenario, that's hasn't happened.
  * Members are preserved asynchronously via a PreserveChildrenJob via SideKiq through the preserve_children method.
  * We use PreservationObject to save the cloud / preserved locations of these files, so that we don't add new metadata values to the objects that we are preserving, thus necessitating another preservation action.

### FileSet walkthrough
Scenario: The ScannedResource with one FileSet is completed.
* PreserveChildrenJob queues a PreserveResourceJob for each of the members.
* PreserveResourceJob is just a wrapper for the Preserver class.
* Preserver
  * `for` factory checks `change_set.preserve?` (again) so it doesn't do
    anything if that's false.
    * https://github.com/pulibrary/figgy/blob/d32622f0585375a3d3cb475a8193f6b345681838/app/services/preserver.rb#L6
* `preserve!` creates a PreservationIntermediaryNode for each file metadata on the FileSet. Gives an option to force the preservation, otherwise only preserves if it hasn't been preserved before.
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
    CheckFixityJob via perform_later.
  * Calls `run_fixity` on the file set, which delegates to the primary_file
      * Runs checksums on the file on disk and compares it to the previously
          stored checksum. If it matches, sets fixity_success to 1, otherwise 0.
  * Sets the output of `run_fixity` to the FileSet, then saves it without
      calling the ChangeSetPersister, bypassing all callbacks. We don't know why
      we do this, but it means the FileSet won't be re-preserved. NOTE: This
      would cause the local FileSet metadata to be different than what's in the
      cloud, if local fixity checks happened after complete. We do see failed
      fixity checks on metadata occasionally.

Scenario: A FileSet exists in Figgy, it should be occasionally confirmed its
fixity is correct.
* `rake figgy:fixity:run` is run manually once by someone, which queues up
    CheckFixityRecursiveJob.
* CheckFixityRecursiveJob runs CheckFixityJob.perform_now on the least recently
    updated FileSet, and then re-enqueues itself. If anything errors, preventing
    re-enqueuing, then it stops running and we'd have to notice via the sidekiq
    dashboard.

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
