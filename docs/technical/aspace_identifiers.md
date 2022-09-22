# ArchiveSpace identifiers

Aspace uses a uri identifier, but also stores what we call collection and
component ids, which were the cannonical ids in our previous system.

We do not use the aspace uri identifiers, although pulfalight does store and display
them for components.

In figgy, staff enter the component IDs and the system does the lookup using
those. There are some edge cases around IDs with dots in them (see below).

## Collection identifiers
Aspace uri identifiers:
- Aspace stores these as "id" and "uri"
- e.g. /repositories/5/resources/4226

About collection ids:
- They may contain a dot
- Aspace stores these as "identifier" and sometimes "ead_id" (may depend on
  whether or not the collection is published)

Example collection ids:
- C1545
- C0744.02

## Component identifiers
Aspace uri identifiers:
- Aspace stores these as "id" and "uri"
- e.g. /repositories/5/archival_objects/1467172

About component ids:
- Published component ids will contain the collection id prepended and joined with an underscore
- Aspace stores them as "ref_id"
- They may contain dashes
- They should not contain dots (beyond the collection id portion) -- Technically this would be allowed but they aren't used.

Example component ids:
- C0140_c79722-72643
- ref7 (this example from an unpublished record, likely a placeholder)
- AC198.03_c5075

## Behavior in various apps

Figgy behavior:
- Figgy expects users to store collection and component ids in their original
  form (e.g. `C0744.02`, not `C0744-02`).
- Figgy transforms dots to dashes when fetching data from pulfalight

Pulfalight behavior:
- pulfalight indexes the identifiers in their dash-replaced form, e.g.
  (`MC001-02-01`, not `MC001.02.01` -- see
  https://findingaids-beta.princeton.edu/catalog/MC001-02-01.json).

Aspace behavior:
- Aspace displays the identifiers in their original form, with dots
  not dashes.
- On export, Aspace provides the identifiers in their original form, prepended
  with `aspace_`, which pulfalight strips off.
