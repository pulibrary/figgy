# Figgy Use Cases

## Multiple representations of the same resource
A resource may have more than one digitized representation. One known use case is where we have digitized and made publicly available the table of contents for an item, and added that to the catalog record as a link to the PDF. Then later a patron requests the item and we digitize it in full to make it available via the Virtual Reading Room / OARSC. The fully-digitized resource needs to be linked to the same catalog record as the excerpt, but needs its own ARK identifier

## Bound-withs / Sammelbands
Several separately-published works may have been bound together into a single volume. This isn't the same as a multi-volume-work because there is a cover and other pages that are unique to the item, and not part of any published work.

Currently Figgy does not handle this use case, and they are ingested as if they were simply a single-codex. They are added to the bib record for whichever item was requested by the patron. This makes it difficult for the patron to find the work they want to use.
