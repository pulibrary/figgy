# 4. Preservation Fixity Checking

Date: 2019-05-03

## Status

Accepted

## Context

We have agreed to check the file integrity of our preserved objects in Google
Cloud Storage by occasionally downloading and comparing the MD5 checksum of
those objects to our stored checksums. This process will happen in a Google
Cloud Function.

## Decisions

1. Fixity Checking Timeline
   1. Every day a random 0.027% of the repository's preserved materials 
      will be queued up to have their integrity checked. This process can be executed via
      ```
      RAILS_ENV=production bundle exec rake fixity:request_daily_cloud_fixity
      ```
      It will be configured as a cron job on a single worker machine.
2. Process
   1. To verify a PreservationObject, each attached FileMetadata will generate a
      message to a Google Cloud Pub/Sub Request Queue in the following format:
      ```json
      {
          "md5": "[md5_of_file]",
          "cloudPath": "[path_in_bucket_converted_from_file_identifier]",
          "preservation_object_id": "[preservation_object_id]",
          "file_metadata_node_id": "[file_metadata_id]",
          "child_property": "[property_file_metadata_node_is_stored_in]"
      }
      ```
   1. A Google Cloud Function will listen for events on the request pub/sub
      topic, download the given cloudPath, and verify the MD5. The cloud
      function will be deployed via developers using the
      `cap [staging/production] deploy:google_cloud_function` command in Figgy.
      - An increased quota (10x default) for inbound traffic must be requested
        from Google to handle the download, and the function restricted to 100 concurrent
        workers. If we need more concurrency later we can request a higher
        inbound traffic quota.
   1. The Google Cloud Function will send a message to a Status Topic, which
      will contain a message giving the status of the operation. It looks like
      the following:
      ```json
      {
        "status": "[SUCCESS/FAILURE]",
        "resource_id": "[preservation_object_id]",
        "child_id": "[file_metadata_id]",
        "child_property": "[property_file_metadata_node_is_stored_in]"
      }
      ```
   1. A daemon will run on each Figgy worker machine which pulls these events
      and sends them to Sidekiq. This worker can be executed via
      `RAILS_ENV=production bundle exec rake fixity:run_worker`, but does not
      manually need to be started - it is handled by a systemd service deployed
      via Ansible.
   1. Sidekiq will create `Event` objects for each status sent, which will be
      displayed in the Fixity Dashboard.

## Consequences

1. Cost
   1. Retrieval of resources from Google Coldline has a hefty cost associated
      with it. If we find that 10% per year is too expensive for the benefits of
      performing these checks we may want to scale that down.
1. Random Checking
   1. 10% a year leaves a lot of room for some resources to never be checked.
      This is purely an investigative measure to ensure the reliability
      guaruntees of Google Cloud Storage as well as validate our preservation process.
      Should failures become evident, we will likely want to check and fix
      everything.
2. Complexity
   1. The above system has a few moving parts which may be difficult to explain.
      However, as we're dealing with many terabytes of data, it's the cheapest
      and most time-efficient method of fixity checking that amount of material.
   2. The decisions above may change depending on how often and how much data we
      end up pulling - if we end up pulling a lot more data, we may want to move
      to Google Nearline over Coldline.
