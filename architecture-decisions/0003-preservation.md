# 3. Preservation

Date: 2019-04-02

## Status

Accepted

## Context

We have agreed with our stakeholders that we will preserve our digital objects by packaging them in
BagIt bags, and storing those bags in cloud storage.  However, there are wide variety of options for
creating bags, how objects are serialized within the bags, and how they are linked to the digital
objects.

## Decisions

1. Creating bags
   1. We will periodically scan for objects which meet the following criteria:
      1. Status is complete
      2. Not bagged more recently than their `updated_at` timestamp
      3. Has a `cloud` preservation policy assigned
   1. In order to avoid redundant processing when there are multiple updates in a short period of time,
      we will not trigger bagging from a ChangeSetPersister or other event-driven mechanism.
1. Packaging bags
   1. We will export an object, and all of its members recursively, including the metadata for any Valkyrie
      object it links to (such as collections, controlled vocabulary terms, etc.).
   1. We will include both files and metadata (serialized as JSON).
   1. We will package the bag directory in a Tar archive, compressed with GZip.
   1. A link to the Tar/GZipped bag file will be added to the object's `file_metadata` property.
   1. We will calculate the MD5 checksum of the Tar/GZipped bag and include it in the `file_metadata`.
   1. We will assign the `file_metadata` a PCDM Use value of `pcdm:preservationArchive`.
1. Transfering bags
   1. After we transfer a bag to cloud storge, we will verify that its MD5 checksum matches the locally-
      calculated value.
   1. We will keep only the most recent bag for an object, overwriting the bag with a new version when the
      object is updated.
1. Deleting bags
   1. There will not be an automated way to delete a bag.  Any deletions will need to be done manually.
   1. When an object is deleted, the preservation bag will not be deleted.

## Consequences

1. Creating bags
   1. There will be a delay between when objects are created and/or updated and when they are bagged.
   1. The scanning frequency will determine how often bags may be redundantly created and uploaded.
1. Packaging bags
   1. Exporting all of the metadata and linked objects with a bag will make it a better preservation package
      because it will include many of the objects that provide context for the object.  However, these will
      also make the bag larger.
   1. Packaging the bags in a Tar/GZip archive will make it easier to work with, transfer, and verify. But
      it will also make it a larger single file, increasing the risk of problems during transfer or copying.
      Compression will reduce file size slightly, but magnify the impact of transfer or copying errors.
   1. Linking from the object to the bag will make it easy to find the bag that preserves an object.  But it
      will also remove the place where the bag is recorded when an object is deleted.
1. Transfering bags
   1. Storing bags in cloud storage makes it much less likely that they will be accidentally corrupted or
      deleted by reducing the number of staff who have access to the bag storage.
   1. Storing bags in cloud storage will store them in a geographically separate area using a separate
      technology stack, reducing vulnerability to natural disaster and malicious attack.
   1. Using MD5 checksums to verify uploading will reduce the possibility of corruption or truncation in 
      transfer.  There is a very small chance that the archive might be compromised with a malicious file
      with a colliding MD5 checksum.  But the risk of this kind of attack is very low.
1. Deleting bags
   1. Deleting bags manually means the last preserved state of the object will persist after it is deleted.
   1. Not deleting bags automatically means that we may accrue bags for deleted objects and waste space. But
      it also means that preservation bags can be used to restore accidentally deleted objects.
