# Tigerdata Freeze

## Scenario

Tigerdata's MediaFlux instance has locked up and all files in the repository are inaccessible. We've received an alert from CheckMK that it's been happening for at least 5 minutes.

## Background Information

We have a CheckMK alert that should tell us about this scenario in #figgy. We've seen it before, and we expect it to happen again. That same alert will be sent to the Tigerdata team in Research Computing.

When Tigerdata is frozen the following will happen:

1. Videos will no longer play (stored in Tigerdata).
1. Original files can't be downloaded.
1. New material can't be ingested - the jobs will hang.
1. Map thumbnails will stop displaying (stored in Tigerdata).

Users will still be able to use viewers and are unlikely to feel the effects, unless they're watching videos.

We don't expect this to happen often.

## Strategy

Our response will depend on how long the event has been ongoing. At each trigger, do the appropriate actions.

### < 1 Hour

No response necessary - the Research Computing team has been notified by the alert, and they'll likely restart the node. The impact to patrons will be minimal, and no data should be lost in the interim.

### 1 - 3 hours

Post a message to #digital-library informing users of the impact of the downtime, and have Figgy's PO message users who may be particularly effected if necessary. A draft of the message:

> @channel Everyone - Figgy's connection to Tigerdata is currently down. Research Data is working with us to get it resolved. In the meantime you'll be unable to do new ingests to Figgy and patrons will be unable to play videos. The data in the repository is still safe - we'll alert you all when things are back to normal.

### > 3 hours, < 1 Day

Send a message to `tigerdata@princeton.edu` asking about the status of the downtime, expected recovery times, and access to the ticket created from the monitor.

### >= 1 Day

Have DLS' Lead message Chuck Bentler on Slack to coordinate recovery efforts and figure out what the blockers are. It should be very unlikely we reach this point. From this point forward consider this a major outage. Send a message to #digital-library that the recovery efforts are taking longer than expected, and that we'll keep them up to date.

## Implications

If all goes well this will minimize messaging to our patrons, block our users the least, and move incidents along at an appropriate pace.

One risk is this system relies on CheckMK successfully sending a message to the Tigerdata team when the node locks up. If that breaks for whatever reason, we won't know about it until the 3 hour mark.
